;;; Copyright 2021 Google LLC
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

(defpackage #:cl-avro.ipc
  (:use #:cl-avro.ipc.error
        #:cl-avro.ipc.message
        #:cl-avro.ipc.protocol)
  (:export #:rpc-error
           #:metadata

           #:undeclared-rpc-error
           #:message

           #:declared-rpc-error
           #:define-error

           #:message
           #:request
           #:response
           #:errors
           #:one-way

           #:protocol
           #:messages
           #:types
           #:md5

           #:protocol-object
           #:transceiver
           #:receive-from-unconnected-client
           #:receive-from-connected-client

           #:stateless-client
           #:stateful-client
           #:send
           #:send-and-receive
           #:send-handshake-p

           #:server
           #:client-protocol))
