(in-package #:restful)


(defclass acceptor (h:acceptor)
  ((resource :initarg :resource
             :type hash-table)))

(defmethod h:acceptor-dispatch-request ((acceptor acceptor) request)
  (let ((path-parts (mapcar #'string-downcase (rest (cl-ppcre:split "/" (hunchentoot:request-uri request))))))
    (handle-uri path-parts (slot-value acceptor 'resource))))

(defun handle-uri (parts resources &optional parent)
  (let* ((keys (mapcar #'string-downcase (a:hash-table-keys resources)))
         (resource-name (find (first parts) keys :test #'string=)))
    (if resource-name
        (if (rest parts)
            (handle-resource parts
                             (gethash resource-name resources)
                             parent)
            (handle-collection (gethash resource-name resources)
                               parent))
        (error-message
         (setf (h:return-code*) h:+http-not-found+)))))

(defun handle-resource (parts resource-hash-value parent)
  (let ((resource-instance (make-instance
                            (gethash :class resource-hash-value)
                            :identifier (second parts)
                            :parent parent)))
    (if (rest (rest parts))
        (handle-uri (rest (rest parts))
                    (gethash :children resource-hash-value)
                    resource-instance)
        (let ((method (h:request-method*)))
          (cond ((eq method :get)
                 (progn
                   (load-resource resource-instance)
                   (jonathan:to-json (view-resource resource-instance))))
                ((eq method :post)
                 (create-resource resource-instance
                                  (jonathan:parse (h:raw-post-data :force-text t))))
                ((eq method :patch)
                 (progn
                   (load-resource resource-instance)
                   (patch-resource resource-instance
                                   (jonathan:parse (h:raw-post-data :force-text t)))))
                ((eq method :delete)
                 (delete-resource resource-instance))
                (t (error-message
                    (setf (h:return-code*) h:+http-method-not-allowed+))))))))

(defun handle-collection (resource-hash-value parent)
  (let ((method (h:request-method*)))
    (cond ((eq method :get)
           (jonathan:to-json
            (view-collection
             (make-instance (gethash :collection resource-hash-value)
                            :parent parent))))
          (t (error-message
              (setf (h:return-code*) h:+http-method-not-allowed+))))))

(defun error-message (code)
  (cond ((= code h:+http-not-found+) "Resource not found.")
        ((= code h:+http-method-not-allowed+) "Method not allowed.")))
