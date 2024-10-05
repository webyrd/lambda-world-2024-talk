(load "faster-miniKanren/test-check.scm")
(load "metaKanren.scm")

;; a
(run* (x)
  (eval-programo
   `(run* (z)
      (conde
        ((== 'cat z))
        ((== 'dog z))))
   x))

;; b
(run 1 (x)
  (eval-programo
   `(run* (z)
      (conde
        ((== ',x z))
        ((== 'dog z))))
   '(cat dog)))

;; c
(run 3 (x)
  (eval-programo
   `(run* (z)
      (conde
        ((== ,x z))
        ((== 'dog z))))
   '(cat dog)))

;; d
(run 3 (x)
  (eval-programo
   `(run* (z)
      (conde
        ((== . ,x))
        ((== 'dog z))))
   '(cat dog)))

;; e
(run* (x)
  (eval-programo
   `(run* (z)
      (,x
       ((== 'cat z))
       ((== 'dog z))))
   '(cat dog)))

;; f
(run* (x)
  (eval-programo
   `(run* (z)
      (letrec-rel ((appendo (l1 l2 l)
                     (conde
                       ((== '() l1) (== l2 l))
                       ((fresh (a d l3)
                          (== (cons a d) l1)
                          (== (cons a l3) l)
                          (appendo d l2 l3))))))
        (appendo '(1 2) '(3 4) z)))
   x))

;; g
(run 1 (x)
  (eval-programo
   `(run* (z)
      (letrec-rel ((appendo (l1 l2 l)
                     (conde
                       ((== . ,x) (== l2 l))
                       ((fresh (a d l3)
                          (== (cons a d) l1)
                          (== (cons a l3) l)
                          (appendo d l2 l3))))))
        (appendo '() '() '())
        (appendo '(a) '(b) '(a b))
        (appendo '(1 2) '(3 4) z)))
   '((1 2 3 4))))

;; h
(run 5 (x y)
  (eval-programo
   `(run* (z)
      (letrec-func ((append (l s)
                      (if (null? l)
                          s
                          (cons (car l) (append (cdr l) s)))))
        (== (append '(a b c) '(d e)) z)
        (== (append ',x ',y) '(1 2 3 4))))
   '((a b c d e))))

;; i
(run* (x)
  (eval-programo
   `(run* (z)
      (let ((y (cons 'cat 'dog)))
        (== 5 z)))
   x))

;; j
(run* (x)
  (eval-programo
   `(run* (z)
      (let ((y (cons 'cat 'dog)))
        (== y z)))
   x))

;; k
(run* (x)
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
          (appendo '(a b c) '(d e) z))))
   x))

;; l
(run* (x y)
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
          (appendo ',x ',y '(a b c d e))
          (== (append ',x '(c d)) z))))
   '((a b c d))))












#!eof
























(test "letrec-func-1"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-func ((make-pair (z) (cons z z)))
          (== (make-pair 'fox) z)))
     x))
  '(((fox . fox))))

(test "letrec-func-2"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-func ((swap-parts (pr) (cons (cdr pr) (car pr))))
          (== (swap-parts (cons 'cat 'dog)) z)))
     x))
  '(((dog . cat))))

(test "letrec-func-3"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-func ((null?? (z) (null? z)))
          (== (cons (null?? '()) (null?? (cons 'cat 'dog))) z)))
     x))
  '(((#t . #f))))

(test "letrec-func-4"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-func ((foo (z) (if (null? z) (cons z z) (car z))))
          (== (cons (foo '()) (foo (cons 'cat 'dog))) z)))
     x))
  '((((() . ()) . cat))))

(test "letrec-append-let-1"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-func ((append (l s)
                        (if (null? l)
                            s
                            (cons (car l) (append (cdr l) s)))))
          (let ((y (append '(a b c) '(d e))))
            (== y z))))
     x))
  '(((a b c d e))))

(test "letrec-append-let-2"
  (run 1 (x)
    (eval-programo
     `(run* (z)
        (letrec-func ((append (l s)
                        (if (null? l)
                            s
                            (cons (car l) (append (cdr l) s)))))
          (let ((y (append ',x '(d e))))
            (== y z))))
     '((a b c d e))))
  '((a b c)))

(test "letrec-append-1"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-func ((append (l s)
                        (if (null? l)
                            s
                            (cons (car l) (append (cdr l) s)))))
          (== (append '(a b c) '(d e)) z)))
     x))
  '(((a b c d e))))

(test "letrec-append-2"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-func ((append (l s)
                        (if (null? l)
                            s
                            (cons (car l) (append (,x l) s)))))
          (== (append '(a b c) '(d e)) z)))
     '((a b c d e))))
  '(cdr))


(test "append+appendo-1"
  (run* (x)
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
            (appendo '(a b c) '(d e) z))))
     x))
  '(((a b c d e))))

(test "append+appendo-2"
  (run* (x)
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
            (appendo (append '(a b) '(c)) '(d e) z))))
     x))
  '(((a b c d e))))

(test "append+appendo-3"
  (run 1 (x)
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
            (appendo (append ',x '(c)) '(d e) z))))
     '((a b c d e))))
  '((a b)))

(test "append+appendo-4"
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
            (appendo ',x ',y '(a b c d e f g))
            (== (append ',x '(d e)) z))))
     '((a b c d e))))
  '(((a b c) (d e f g))))

(test "append+appendo-5a"
  
  '(((a b) (c d e))))


(test "append+appendo-5aa"
  (run* (x y)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                         (conde
                           ((== '() l1) (== l2 l))
                           ((fresh (a d l3)
                              (== (cons a d) l1)
                              (== (cons a l3) l)
                              (appendo d l2 l3))))))
          (letrec-func ((append (l s)
                                (if (null? l)
                                    s
                                    (cons (car l) (append (cdr l) s)))))
            (appendo ',x ',y '(a b c d e))
            (== (append ',x '(c d)) z))))
     '((a b c d))))
  '(((a b) (c d e))))

(test "append+appendo-5ab"
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
            (let ((w (append ',x '(c d))))
              (appendo ',x ',y '(a b c d e))
              (== w z)))))
     '((a b c d))))
  '(((a b) (c d e))))

;; WEB run 2 seems to take a long time or diverge
(test "append+appendo-5b"
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
            (== (append ',x '(c d)) z)
            (appendo ',x ',y '(a b c d e)))))
     '((a b c d))))
  '(((a b) (c d e))))

(test "append+appendo-5c"
  (run 1 (x y)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (letrec-func ((append (l s)
                          (if (null? l)
                              s
                              (cons (car l) (append (cdr l) s)))))
            (== (append ',x '(c d)) z)
            (appendo ',x ',y '(a b c d e)))))
     '((a b c d))))
  '(((a b) (c d e))))

(test "append+appendo-6"
  (run 1 (x)
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
            (let ((w (append ',x '(c d))))
              (appendo '(a) z w)))))
     '((b c d))))
  '((a b)))

(test "append+appendo-7"
  (run 1 (x)
    (eval-programo
     `(run* (z)
        (letrec-func ((append (l s)
                        (if (null? l)
                            s
                            (cons (car l) (append (cdr l) s)))))
          (letrec-rel ((appendo (l1 l2 l)
                         (conde
                           ((== '() l1) (== l2 l))
                           ((fresh (a d ,x)
                              (== (cons a d) l1)
                              (== (cons a l3) l)
                              (appendo d l2 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  (== (cons a1 (cons a2 (cons a3 '()))) z)
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)
                  (appendo '(c d) '(e f) a3)))))))
     '((() (a b) (c d e f)))))
  '(l3))

(test "append+appendo-8"
  (run* (x)
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
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  (== (cons a1 (cons a2 (cons a3 '()))) z)
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)
                  (appendo '(c d) '(e f) a3)))))))
     x))
  '(((() (a b) (c d e f)))))






(test "interesting 1"
  (run* (x)
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
                                     (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  ;;(== (cons a1 (cons a2 (cons a3 '()))) z)
                  (== a3 z)
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)
                  (appendo '(c d) '(e f) a3)))))))
     '((c d e f))))
  '(_.0))

(test "interesting 2"
  (run* (x)
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
                                     (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  ;;(== (cons a1 (cons a2 (cons a3 '()))) z)
                                        ;(== a3 z)
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)
                  (appendo '(c d) '(e f) z)))))))
     '((c d e f))))
  '())

(test "interesting 3"
  (run* (x)
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
                              (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  ;;(== (cons a1 (cons a2 (cons a3 '()))) z)
                  ;;(== a3 z)
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)
                  (appendo '(c d) '(e f) z)))))))
     x))
  '(((c d _.))))

(test "interesting 4"
  (run* (x)
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
                              (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  ;;(== (cons a1 (cons a2 (cons a3 '()))) z)
                  ;;(== a3 z)
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)
                  (appendo '(c d) '(e f) z)))))))
     x)
    (== '((c d e f)) x))
  '())

(test "interesting 5"
  (run* (x)
    (== '((c d e f)) x)
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
                              (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  ;;(== (cons a1 (cons a2 (cons a3 '()))) z)
                  (== a3 z)
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)
                  (appendo '(c d) '(e f) z)))))))
     x))
  '(((c d e f))))

(test "interesting 7"
  (run* (x)
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
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  (== (cons a1 (cons a2 (cons a3 '()))) '(() (a b) (c d e f)))
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)
                  (appendo '(c d) '(e f) z)))))))
     x))
  '(((c d e f))))

(test "interesting 8"
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
            (let ((w (append ',x ',y)))
              (== w z)))))
     '((a b c d e))))
  '((() (a b c d e))))




(test "weird-appendo-1"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l3 l3))))))
          (appendo '() '() '())
          (appendo '(a) '(b) '(a b))
          (appendo '(c d) '(e f) '(c d e f))
          (appendo '(g h i) '(j k l) z)))
     x))
  '(((g h i _.))))

(test "weird-appendo-2"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (appendo '() '() '())
          (appendo '(a) '(b) '(a b))
          (appendo '(c d) '(e f) '(c d e f))
          (appendo '(g h i) '(j k l) z)))
     x))
  '(((g h i j k l))))

(test "weird-appendo-3"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l3 l3))))))
          (appendo '() '() '())
          (appendo '(a) '(b) '(a b))
          (appendo '(c d) '(e f) '(c d e f))
          (appendo '(g h i) '(j k l) z)))
     '((g h i j k l))))
  '())

(test "weird-appendo-4"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (appendo '() '() '())
          (appendo '(a) '(b) '(a b))
          (appendo '(c d) '(e f) '(c d e f))
          (appendo '(g h i) '(j k l) z)))
     '((g h i j k l))))
  '(_.0))



(test "conde-1"
  (run* (x)
    (eval-programo
     `(run* (z)
        (conde
          ((== z 'cat))))
     x))
  '((cat)))

(test "conde-2"
  (run* (x)
    (eval-programo
     `(run* (z)
        (conde
          ((== z 'cat) (== 'dog 'dog) (== z z))))
     x))
  '((cat)))

(test "conde-3"
  (run* (x)
    (eval-programo
     `(run* (z)
        (conde
          ((== z 'cat) (== 'dog z))))
     x))
  '(()))

(test "conde-4"
  (run* (x)
    (eval-programo
     `(run* (z)
        (conde
          ((== z 'cat))
          ((== 'dog z))))
     x))
  '((cat dog)))

(test "conj*-0a"
  (run* (x)
    (eval-programo
     `(run* (z)
        (== z 1))
     x))
  '((1)))

(test "conj*-0a"
  (run* (x)
    (eval-programo
     `(run* (z)
        (conj*
         (== z 'cat)
         (conj*)))
     x))
  '((cat)))

(test "run*-0a"
  (run* (x)
    (eval-programo
     `(run* (z)
        (== z 'cat)
        (== 'cat z))
     x))
  '((cat)))

(test "run*-0b"
  (run* (x)
    (eval-programo
     `(run* (z)
        (== z 'cat)
        (== 'dog z))
     x))
  '(()))

(test "run-0"
  (run* (x)
    (eval-programo
     `(run ,(peano 0) (z)
        (== z 'cat)
        (== 'cat z))
     x))
  '(()))

(test "run-1"
  (run* (x)
    (eval-programo
     `(run ,(peano 1) (z)
        (== z 'cat)
        (== 'cat z))
     x))
  '((cat)))

(test "run-2"
  (run* (x)
    (eval-programo
     `(run ,(peano 2) (z)
        (== z 'cat)
        (== 'cat z))
     x))
  '((cat)))

