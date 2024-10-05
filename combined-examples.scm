(load "faster-miniKanren/test-check.scm")
(load "metaKanren.scm")
(load "full-interp.scm")

(test "appendo-0a"
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
  '((a b c d e)))

(test "appendo-0b"
  (run* (y)
    (evalo
     `(letrec ((append
                (lambda (l s)
                  (if (null? l)
                      s
                      (cons (car l) (append (cdr l) s))))))
        (append '(1 2) '(3 4 5)))
     y))
  '((1 2 3 4 5)))

(test "appendo-and-append-0"
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
  '(((a b c d e) (1 2 3 4 5))))

(test "appendo-and-append-1"
  (time
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
       '(a b 1 2 3))))
  '((() (a b c d e) (a b 1 2 3))
    ((a) (b c d e) (b 1 2 3))
    ((a b) (c d e) (1 2 3))))

(test "appendo-and-append-and-appendo-0"
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
  '(((a b c d e) (1 2 3 4 5) ((cat dog fish rat)))))

(test "appendo-and-append-and-appendo-and-append-0"
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
  '(((a b c d e) (1 2 3 4 5) ((cat dog fish rat)))))

(test "appendo-and-append-and-appendo-and-append-1"
  (time
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
       '((cat dog fish rat)))))
  '(((d e) s l l1)))

(test "appendo-and-append-a"
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
  '((appendo append)))

(test "appendo-and-append-b"
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
  '((appendo append append)))

(test "appendo-and-append-c"
  (time
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
      '((cat dog fish rat)))))
  '((appendo l append)))

(test "appendo-and-append-d"
  (time
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
      '((cat dog fish rat)))))
  '((l cons appendo append)))

(test "appendo-collecting-1"
  (time
   (run* (x)
     (eval-programo
      `(run* (z)
         (fresh (a b)
           (letrec-rel ((appendo (l1 l2 l)
                          (conde
                            ((== '() l1) (== l2 l))
                            ((fresh (a d l3)
                               (== (cons a d) l1)
                               (== (cons a l3) l)
                               (appendo d l2 l3))))))
             (== (cons a (cons b '())) z)
             (appendo a b '(a b c d e)))))
      x)))
  '(((() (a b c d e))
     ((a) (b c d e))
     ((a b) (c d e))
     ((a b c) (d e))
     ((a b c d) (e))
     ((a b c d e) ()))))

;; WEB slow or divergent
#;(test "appendo-collecting-2a"
  (time
   (run 1 (x)
     (letrec ((membero
               (lambda (x l)
                 (fresh (e e*)
                   (== `(,e . ,e*) l)
                   (conde
                     ((== x e))
                     ((=/= x e) (membero x e*)))))))
       (fresh ()
         (membero '((a b) (c d e)) x)
         (eval-programo
          `(run* (z)
             (fresh (a b c)
               (letrec-rel ((appendo (l1 l2 l)
                                     (conde
                                       ((== '() l1) (== l2 l))
                                       ((fresh (a d l3)
                                          (== (cons a d) l1)
                                          (== (cons a l3) l)
                                          (appendo d l2 l3))))))
                 (== (cons a (cons b '())) z)
                 (appendo a b c))))
          x)))))
  '???)

;; WEB slow or divergent
#;(test "appendo-collecting-2b"
  (time
   (run 1 (x)
     (letrec ((membero
               (lambda (x l)
                 (fresh (e e*)
                   (== `(,e . ,e*) l)
                   (conde
                     ((== x e))
                     ((=/= x e) (membero x e*)))))))
       (fresh ()
         (eval-programo
          `(run* (z)
             (fresh (a b c)
               (letrec-rel ((appendo (l1 l2 l)
                                     (conde
                                       ((== '() l1) (== l2 l))
                                       ((fresh (a d l3)
                                          (== (cons a d) l1)
                                          (== (cons a l3) l)
                                          (appendo d l2 l3))))))
                 (== (cons a (cons b '())) z)
                 (appendo a b c))))
          x)
         (membero '((a b) (c d e)) x)))))
  '???)

;; WEB slow or divergent
#;(test "appendo-collecting-2c"
  (time
   (run 1 (x)
     (letrec ((membero
               (lambda (x l)
                 (fresh (e e*)
                   (== `(,e . ,e*) l)
                   (conde
                     ((== x e))
                     ((=/= x e) (membero x e*)))))))
       (fresh ()
         (membero '(() (a b c d e)) x)
         (eval-programo
          `(run* (z)
             (fresh (a b c)
               (letrec-rel ((appendo (l1 l2 l)
                                     (conde
                                       ((== '() l1) (== l2 l))
                                       ((fresh (a d l3)
                                          (== (cons a d) l1)
                                          (== (cons a l3) l)
                                          (appendo d l2 l3))))))
                 (== (cons a (cons b '())) z)
                 (appendo a b c))))
          x)))))
  '???)

;; WEB slow or divergent
#;(test "appendo-collecting-3c"
  (time
   (run 1 (x)
     (letrec ((membero
               (lambda (x l)
                 (fresh (e e*)
                   (== `(,e . ,e*) l)
                   (conde
                     ((== x e))
                     ((=/= x e) (membero x e*)))))))
       (fresh ()
         (membero '(() (a b c)) x)
         (eval-programo
          `(run* (z)
             (fresh (a b c)
               (letrec-rel ((appendo (l1 l2 l)
                                     (conde
                                       ((== '() l1) (== l2 l))
                                       ((fresh (a d l3)
                                          (== (cons a d) l1)
                                          (== (cons a l3) l)
                                          (appendo d l2 l3))))))
                 (== (cons a (cons b '())) z)
                 (appendo a b c))))
          x)))))
  '???)
