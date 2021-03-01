;;; Copyright (C) 2019-2021 Sahil Kang <sahil.kang@asilaycomputing.com>
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
(defpackage #:cl-avro.io.base
  (:use #:cl)
  (:export #:serialize
           #:deserialize))
(in-package #:cl-avro.io.base)

(defgeneric serialize (object &key stream &allow-other-keys)
  (:documentation
   "Serialize OBJECT into STREAM.

If STREAM is nil, then the serialized object is returned, instead."))

(defgeneric deserialize (schema input &key &allow-other-keys)
  (:documentation
   "Deserialize an instance of SCHEMA from INPUT."))