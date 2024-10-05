(load "faster-miniKanren/test-check.scm")
(load "metaKanren.scm")
(load "full-interp.scm")

;; 1
(run* (x)
  (letrec ((appendo
            (lambda (l1 l2 l)
              (conde
                ((== '() l1) (== l2 l))
                ((fresh (a d l3)
                   (== (cons a d) l1)
                   (== (cons a l3) l)
                   (appendo d l2 l3)))))))
    (appendo '(a b c) '(d e) x)))

;; 2
(run* (y)
  (evalo
   `(letrec ((append
              (lambda (l s)
                (if (null? l)
                    s
                    (cons (car l) (append (cdr l) s))))))
      (append '(1 2) '(3 4 5)))
   y))

;; 3
(run* (x y)
  (letrec ((appendo
            (lambda (l1 l2 l)
              (conde
                ((== '() l1) (== l2 l))
                ((fresh (a d l3)
                   (== (cons a d) l1)
                   (== (cons a l3) l)
                   (appendo d l2 l3)))))))
    (appendo '(a b c) '(d e) x))
  (evalo
   `(letrec ((append (lambda (l s)
                       (if (null? l)
                           s
                           (cons (car l) (append (cdr l) s))))))
      (append '(1 2) '(3 4 5)))
   y))

;; 4
(run* (x y w)
  (letrec ((appendo
            (lambda (l1 l2 l)
              (conde
                ((== '() l1) (== l2 l))
                ((fresh (a d l3)
                   (== (cons a d) l1)
                   (== (cons a l3) l)
                   (appendo d l2 l3)))))))
    (appendo x y '(a b c d e)))
  (evalo
   `(letrec ((append 
              (lambda (l s)
                (if (null? l)
                    s
                    (cons (car l) (append (cdr l) s))))))
      (append ',x ',w))
   '(a b 1 2 3)))

;; 5
(run* (x y w)
  (letrec ((appendo
            (lambda (l1 l2 l)
              (conde
                ((== '() l1) (== l2 l))
                ((fresh (a d l3)
                   (== (cons a d) l1)
                   (== (cons a l3) l)
                   (appendo d l2 l3)))))))
    (appendo '(a b c) '(d e) x))
  (evalo
   `(letrec ((append 
              (lambda (l s)
                (if (null? l)
                    s
                    (cons (car l) (append (cdr l) s))))))
      (append  '(1 2) '(3 4 5)))
   y)
  (eval-programo
   `(run* (z)
      (letrec-rel ((appendo (l1 l2 l)
                     (conde
                       ((== '() l1) (== l2 l))
                       ((fresh (a d l3)
                          (== (cons a d) l1)
                          (== (cons a l3) l)
                          (appendo d l2 l3))))))
        (appendo '(cat dog) '(fish rat) z)))
   w))

;; 6
(run* (x y w)
  (letrec ((appendo
            (lambda (l1 l2 l)
              (conde
                ((== '() l1) (== l2 l))
                ((fresh (a d l3)
                   (== (cons a d) l1)
                   (== (cons a l3) l)
                   (appendo d l2 l3)))))))
    (appendo '(a b c) '(d e) x))
  (evalo
   `(letrec ((append 
              (lambda (l s)
                (if (null? l)
                    s
                    (cons (car l) (append (cdr l) s))))))
      (append  '(1 2) '(3 4 5)))
   y)
  (eval-programo
   `(run* (z)
      (letrec-func ((append (l s)
                      (if (null? l)
                          s
                          (cons (car l) (append (cdr l) s)))))
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (appendo (append '(cat) '(dog)) '(fish rat) z))))
   w))

;; 7
(run 1 (v w x y)
  (letrec ((appendo
            (lambda (l1 l2 l)
              (conde
                ((== '() l1) (== l2 l))
                ((fresh (a d l3)
                   (== (cons a d) l1)
                   (== (cons a l3) l)
                   (appendo d l2 l3)))))))
    (appendo '(a b c) v '(a b c d e)))
  (evalo
   `(letrec ((append 
              (lambda (l s)
                (if (null? l)
                    ,w
                    (cons (car l) (append (cdr l) s))))))
      (append  '(1 2) '(3 4 5)))
   '(1 2 3 4 5))
  (eval-programo
   `(run* (z)
      (letrec-func ((append (l s)
                      (if (null? l)
                          s
                          (cons (car ,x) (append (cdr l) s)))))
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) ,y)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (appendo (append '(cat) '(dog)) (append '(fish) '(rat)) z))))
   '((cat dog fish rat))))

;; 8
(run 1 (x y)
  (eval-programo
   `(run* (z)
      (letrec-func ((append (l s)
                      (if (null? l)
                          s
                          (cons (car l) (append (cdr l) s)))))
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (,x (append '(cat) '(dog)) (,y '(fish) '(rat)) z))))
   '((cat dog fish rat))))

;; 9
(run 1 (w x y)
  (eval-programo
   `(run* (z)
      (letrec-func ((append (l s)
                      (if (null? l)
                          s
                          (cons (car l) (append (cdr l) s)))))
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (,w (,x '(cat) '(dog)) (,y '(fish) '(rat)) z))))
   '((cat dog fish rat))))

;; 10
(run 1 (w x y)
  (eval-programo
   `(run* (z)
      (letrec-func ((append (l s)
                      (if (null? l)
                          s
                          (cons (car ,x) (append (cdr l) s)))))
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (,w (append '(cat) '(dog)) (,y '(fish) '(rat)) z))))
   '((cat dog fish rat))))

;; 11
(run 1 (v w x y)
  (eval-programo
   `(run* (z)
      (letrec-func ((append (l s)
                      (if (null? l)
                          s
                          (cons (car ,v) (append (cdr l) s)))))
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (,w a d) l1)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (,x (append '(cat) '(dog)) (,y '(fish) '(rat)) z))))
   '((cat dog fish rat))))
