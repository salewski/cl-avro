;;; Copyright (C) 2019-2020 Sahil Kang <sahil.kang@asilaycomputing.com>
;;;
;;; This file is part of cl-avro.
;;;
;;; cl-avro is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; cl-avro is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with cl-avro.  If not, see <http://www.gnu.org/licenses/>.

(in-package #:cl-user)
(defpackage #:cl-avro.object-container-file.file-block
  (:use #:cl)
  (:shadow #:count)
  (:local-nicknames
   (#:schema #:cl-avro.schema)
   (#:io #:cl-avro.io)
   (#:header #:cl-avro.object-container-file.header))
  (:shadowing-import-from #:cl-avro.schema
                          #:bytes)
  (:export #:file-block
           #:count
           #:bytes

           #:file-block-objects
           #:make-file-block-objects
           #:file-block-objects-header
           #:file-block-objects-objects))
(in-package #:cl-avro.object-container-file.file-block)

(defclass file-block ()
  ((count
    :reader count
    :type schema:long)
   (bytes
    :reader bytes
    :type schema:bytes)
   (sync
    :reader header:sync
    :type header:sync))
  (:metaclass schema:record)
  (:name "file_block")
  (:documentation
   "A file data block for an avro object container file."))

(declaim
 (ftype (function (header:header file-block) (values &optional))
        assert-valid-sync-marker)
 (inline assert-valid-sync-marker))
(defun assert-valid-sync-marker (header file-block)
  (declare (optimize (speed 3) (safety 0)))
  (let ((header-sync (schema:bytes (header:sync header)))
        (block-sync (schema:bytes (header:sync file-block))))
    (declare ((simple-array (unsigned-byte 8) (16)) header-sync block-sync))
    (unless (equalp header-sync block-sync)
      (error "File block sync marker does not match header's")))
  (values))
(declaim (notinline assert-valid-sync-marker))

(declaim
 (ftype (function (header:codec (simple-array (unsigned-byte 8) (*)))
                  (values (simple-array (unsigned-byte 8) (*)) &optional))
        %decompress)
 (inline %decompress))
(defun %decompress (codec bytes)
  (declare (optimize (speed 3) (safety 0)))
  (ecase codec
    (header:null bytes)
    (header:deflate (chipz:decompress nil 'chipz:deflate bytes))
    (header:bzip2 (chipz:decompress nil 'chipz:bzip2 bytes))))
(declaim (notinline %decompress))

(declaim
 (ftype (function (header:header file-block)
                  (values io:memory-input-stream &optional))
        decompress)
 (inline decompress))
(defun decompress (header file-block)
  (declare (optimize (speed 3) (safety 0))
           (inline %decompress))
  (let ((codec (header:codec header))
        (bytes (bytes file-block)))
    (make-instance 'io:memory-input-stream :bytes (%decompress codec bytes))))
(declaim (notinline decompress))

(defstruct (file-block-objects (:copier nil)
                               (:predicate nil))
  (header (error "Must supply HEADER")
   :type header:header :read-only t)
  (objects (error "Must supply OBJECTS")
   :type (simple-array schema:schema (*)) :read-only t))

(defmethod io:deserialize
    ((header header:header) (file-block file-block) &key)
  "Read a vector of objects from FILE-BLOCK."
  (declare (optimize (speed 3) (safety 0))
           (inline assert-valid-sync-marker decompress))
  (assert-valid-sync-marker header file-block)
  (loop
    with count = (count file-block)
    and stream = (decompress header file-block)
    and schema = (header:schema header)
    with vector = (make-array count :element-type schema)

    for i below count
    for object = (io:deserialize schema stream)
    do (setf (elt vector i) object)

    finally
       (return
         (make-file-block-objects :header header :objects vector))))

(declaim
 (ftype (function (header:codec (simple-array (unsigned-byte 8) (*)))
                  (values (simple-array (unsigned-byte 8) (*)) &optional))
        compress)
 (inline compress))
(defun compress (codec bytes)
  (declare (optimize (speed 3) (safety 0)))
  (ecase codec
    (header:null bytes)
    (header:deflate (salza2:compress-data bytes 'salza2:deflate-compressor))))
(declaim (notinline compress))

(declaim
 (ftype (function ((vector (unsigned-byte 8)))
                  (values (simple-array (unsigned-byte 8) (*)) &optional))
        coerce-vector)
 (inline coerce-vector))
(defun coerce-vector (vector)
  (declare (optimize (speed 3) (safety 0)))
  ;; TODO this copying sucks...see todo for memory-output-stream
  (coerce vector '(simple-array (unsigned-byte 8) (*))))
(declaim (notinline coerce-vector))

(declaim
 (ftype (function (file-block-objects) (values file-block &optional))
        to-file-block)
 (inline to-file-block))
(defun to-file-block (file-block-objects)
  (declare (optimize (speed 3) (safety 0))
           (inline compress coerce-vector))
  (loop
    with header = (file-block-objects-header file-block-objects)
    and objects = (file-block-objects-objects file-block-objects)
    and stream = (make-instance 'io:memory-output-stream)

    for object across objects
    do (io:serialize object :stream stream)

    finally
       (return
         (make-instance
          'file-block
          :count (length objects)
          :bytes (compress (header:codec header)
                           (coerce-vector (io:bytes stream)))
          :sync (header:sync header)))))
(declaim (notinline to-file-block))

(defmethod io:serialize
    ((object file-block-objects) &key stream)
  (declare (optimize (speed 3) (safety 0))
           (inline to-file-block))
  (io:serialize (to-file-block object) :stream stream)
  (values))
