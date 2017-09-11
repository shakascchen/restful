
(in-package :restful)

(defclass agraph-storage ()
  ((storage :reader storage)
   (resource-class-name :initarg resource-class-name) ;later to make this slot required
  (:documentation "Restful's storage by storing the data in AllegroGraph.")))

(defmethod get-items ((storage agraph-storage))
  
