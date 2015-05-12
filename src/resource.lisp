(in-package #:restful)


(define-condition resource-not-found-error (error) ())

(defclass resource ()
  ((identifier :initarg :identifier :reader identifier)
   (parent :initarg :parent :type resource)
   (storage :initarg :storage :type storage :reader storage)))

(defgeneric view-resource (resource)
  (:documentation "This function should return an object that will be
serialized to json using the jonathan library."))

(defgeneric load-resource (resource)
  (:documentation "This function loads a resource based on its identifier."))

(defgeneric replace-resource (resource post-data)
  (:documentation "This function replaces a resource."))

(defgeneric create-resource (resource post-data)
  (:documentation "This function creates a new resource."))

(defgeneric patch-resource (resource post-data)
  (:documentation "This function patches an existing resource."))

(defgeneric delete-resource (resource)
  (:documentation "This function deletes an existing resource."))

(defmethod view-resource ((resource resource))
  (let ((slots (resource-get-slots resource)))
    (a:flatten
     (mapcar #'(lambda (slot)
                 (list (intern (symbol-name slot) :keyword) (slot-value resource
                                                                        slot)))
             slots))))

(defmethod load-resource ((resource resource)))

(defmethod replace-resource ((resource resource) post-data))

(defmethod create-resource ((resource resource) post-data))

(defmethod patch-resource ((resource resource) post-data))

(defmethod delete-resource ((resource resource))
  (delete-item (storage resource) (identifier resource)))

(defun resource-equal (resource1 resource2)
  (equal (resource-normalize resource1)
         (resource-normalize resource2)))

(defun resource-normalize (resource)
  (a:flatten (sort (a:plist-alist resource)
                   #'(lambda (a b)
                       (< (cdr a) (cdr b))))))

(defun resource-get-slots (resource)
  (remove-if #'(lambda (slot)
                 (or (eq slot 'parent)
                     (eq slot 'storage)))
             (mapcar #'closer-mop:slot-definition-name
                     (closer-mop:class-slots resource))))
