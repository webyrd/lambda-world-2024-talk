(load "faster-miniKanren/test-check.scm")
(load "metaKanren.scm")

#|
;; WEB
(test "occurs-check-1"
  (run* (x)
    (eval-programo
     `(run* (z)
        (== (cons z z) z))
     x))
  '())
|#

(test "double-appendo-1"
  (time
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
      (eval-programo
       `(run* (z)
          (letrec-rel ((appendo (l1 l2 l)
                         (conde
                           ((== '() l1) (== l2 l))
                           ((fresh (a d l3)
                              (== (cons a d) l1)
                              (== (cons a l3) l)
                              (appendo d l2 l3))))))
            (appendo '(cat dog) '() '(cat dog))
            (appendo '(apple) '(peach) '(apple peach))
            (appendo '(1 2) '(3 4) z)))
       y)))
  '(((a b c d e) ((1 2 3 4)))))

;; WEB run 4 is slow or diverges (there should only be 3 answers)
(test "double-appendo-2"
  (time
   (run 3 (x y w)
     (letrec ((appendo
               (lambda (l1 l2 l)
                 (conde
                   ((== '() l1) (== l2 l))
                   ((fresh (a d l3)
                      (== (cons a d) l1)
                      (== (cons a l3) l)
                      (appendo d l2 l3)))))))
       (appendo x y '(a b c d e)))
     (eval-programo
      `(run* (z)
         (letrec-rel ((appendo (l1 l2 l)
                               (conde
                                 ((== '() l1) (== l2 l))
                                 ((fresh (a d l3)
                                    (== (cons a d) l1)
                                    (== (cons a l3) l)
                                    (appendo d l2 l3))))))
           (appendo ',x ',w z)))
      '((a b 1 2 3)))))
  '((() (a b c d e) (a b 1 2 3))
    ((a) (b c d e) (b 1 2 3))
    ((a b) (c d e) (1 2 3))))

(test "double-appendo-2b"
  (time
   (run 2 (x y w)
     (eval-programo
      `(run* (z)
         (letrec-rel ((appendo (l1 l2 l)
                               (conde
                                 ((== '() l1) (== l2 l))
                                 ((fresh (a d l3)
                                    (== (cons a d) l1)
                                    (== (cons a l3) l)
                                    (appendo d l2 l3))))))
           (appendo ',x ',w z)))
      '((a b 1 2 3)))
     (letrec ((appendo
               (lambda (l1 l2 l)
                 (conde
                   ((== '() l1) (== l2 l))
                   ((fresh (a d l3)
                      (== (cons a d) l1)
                      (== (cons a l3) l)
                      (appendo d l2 l3)))))))
       (appendo x y '(a b c d e)))))
  '((() (a b c d e) (a b 1 2 3))
    ((a) (b c d e) (b 1 2 3))))

(test "cat-dog-1"
  (run* (x)
    (eval-programo
     `(run* (z)
        (conde
          ((== 'cat z))
          ((== 'dog z))))
     x))
  '((cat dog)))

(test "cat-dog-2"
  (run 1 (x)
    (eval-programo
     `(run* (z)
        (conde
          ((== ',x z))
          ((== 'dog z))))
     '(cat dog)))
  '(cat))

(test "cat-dog-2b"
  (run 3 (x)
    (eval-programo
     `(run* (z)
        (conde
          ((== ,x z))
          ((== 'dog z))))
     '(cat dog)))
  '('cat
    ((car '(cat . _.0))
     (absento (closr _.0) (var _.0)))
    ((cdr '(_.0 . cat))
     (absento (closr _.0) (var _.0)))))

(test "cat-dog-3"
  (run 3 (x)
    (eval-programo
     `(run* (z)
        (conde
          ((== . ,x))
          ((== 'dog z))))
     '(cat dog)))
  '((z 'cat)
    ('cat z)
    ((z (car '(cat . _.0)))
     (absento (closr _.0) (var _.0)))))

#| WEB slow or diverges
(test "cat-dog-4"
  (run 1 (x)
    (eval-programo
     `(run* (z)
        (conde
          (,x)
          ((== 'dog z))))
     '(cat dog)))
  '((z 'cat)))
|#

(test "cat-dog-5"
  (run* (x)
    (eval-programo
     `(run* (z)
        (,x
          ((== 'cat z))
          ((== 'dog z))))
     '(cat dog)))
  '(conde))


(test "seems-broken-1"
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
                                     ;; replaced l2 with l3                                     
                                     (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  ;; Suspect!
                  ;;(== a3 z)
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)
                  (appendo '(c d) '(e f) z)))))))
     '((c d e f))))
  '())

(test "seems-broken-2"
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
                                     ;; replaced l2 with l3                                     
                                     (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  ;; seems broken: uncommenting (== a3 z) makes a failing query succeed
                  (== a3 z)
                  ;;
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)
                  (appendo '(c d) '(e f) z)))))))
     '((c d e f))))
  '(_.0))

(test "seems-broken-3"
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
                                     ;; replaced l2 with l3                                     
                                     (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)
                  (appendo '(c d) '(e f) z)
                  ;; seems broken: uncommenting (== a3 z) makes a failing query succeed
                  (== a3 z)
                  ;;
                  ))))))
     '((c d e f))))
  '(_.0))

(test "seems-broken-4"
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
                                     ;; replaced l2 with l3                                     
                                     (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  (appendo '(c d) '(e f) z)
                  ;; seems broken: uncommenting (== a3 z) makes a failing query succeed
                  (== a3 z)
                  ;;
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)))))))
     '((c d e f))))
  '(_.0))

(test "seems-broken-5"
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
                                     ;; replaced l2 with l3                                     
                                     (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (let ((a3 (append '(c d) '(e f))))
                  (appendo '(c d) '(e f) z)
                  ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
                  (== '(c d e f) z)
                  ;;
                  (appendo '() '() a1)
                  (appendo '(a) '(b) a2)))))))
     '((c d e f))))
  '(_.0))

(test "seems-broken-6"
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
                                     ;; replaced l2 with l3                                     
                                     (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (let ((a2 (append '(a) '(b))))
                (appendo '(c d) '(e f) z)
                ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
                (== '(c d e f) z)
                ;;
                (appendo '() '() a1)
                (appendo '(a) '(b) a2))))))
     '((c d e f))))
  '(_.0))

;; interesting--removing the middle `let` changes the behavior, resulting in failure
(test "seems-broken-7"
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
                                     ;; replaced l2 with l3                                     
                                     (appendo d l3 l3))))))
            (let ((a1 (append '() '())))
              (appendo '(c d) '(e f) z)
              ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
              (== '(c d e f) z)
              ;;
              (appendo '() '() a1)
              (appendo '(a) '(b) a2)))))
     '((c d e f))))
  '())

(test "seems-broken-8"
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
                                     ;; replaced l2 with l3                                     
                                     (appendo d l3 l3))))))
            (appendo '(c d) '(e f) z)
            ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
            (== '(c d e f) z)
            ;;
            (appendo '() '() '())
            (appendo '(a) '(b) '(a b)))))
     '((c d e f))))
  '(_.0))

(test "seems-broken-8-commented"
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
                                     ;; replaced l2 with l3                                     
                                     (appendo d l3 l3))))))
            (appendo '(c d) '(e f) z)
            ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
            ;;(== '(c d e f) z)
            ;;
            (appendo '() '() '())
            (appendo '(a) '(b) '(a b)))))
     '((c d e f))))
  '())

(test "seems-broken-9"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                                (conde
                                  ((== '() l1) (== l2 l))
                                  ((fresh (a d l3)
                                     (== (cons a d) l1)
                                     (== (cons a l3) l)
                                     ;; replaced l2 with l3                                     
                                     (appendo d l3 l3))))))
            (appendo '(c d) '(e f) z)
            ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
            (== '(c d e f) z)
            ;;
            (appendo '() '() '())
            (appendo '(a) '(b) '(a b))))
     '((c d e f))))
  '(_.0))

(test "seems-broken-9-commented"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                                (conde
                                  ((== '() l1) (== l2 l))
                                  ((fresh (a d l3)
                                     (== (cons a d) l1)
                                     (== (cons a l3) l)
                                     ;; replaced l2 with l3                                     
                                     (appendo d l3 l3))))))
            (appendo '(c d) '(e f) z)
            ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
            ;(== '(c d e f) z)
            ;;
            (appendo '() '() '())
            (appendo '(a) '(b) '(a b))))
     '((c d e f))))
  '())

(test "seems-broken-10a"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            ;; replaced l2 with l3                                     
                            (appendo d l3 l3))))))
          (appendo '(c d) '(e f) z)
          ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
          (== '(c d e f) z)
          ;;
          ))
     '((c d e f))))
  '(_.0))

(test "seems-broken-10b"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            ;; replaced l2 with l3                                     
                            (appendo d l3 l3))))))
          ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
          (== '(c d e f) z)
          ;;          
          (appendo '(c d) '(e f) z)
          ))
     '((c d e f))))
  '(_.0))

(test "seems-broken-10-commented"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            ;; replaced l2 with l3                                     
                            (appendo d l3 l3))))))
          (appendo '(c d) '(e f) z)
          ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
          ;;(== '(c d e f) z)
          ;;
          ))
     '((c d e f))))
  '())

;; WEB I see--so it isn't broken!!  Compare this result with "seems-broken-11b"
;; It's the reification that causes the apparent problem.
(test "seems-broken-11a"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            ;; replaced l2 with l3                                     
                            (appendo d l3 l3))))))
          (appendo '(c d) '(e f) z)
          ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
          (== '(c d e f) z)
          ;;
          ))
     x))
  '(((c d e f))))

(test "seems-broken-11b"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            ;; replaced l2 with l3                                     
                            (appendo d l3 l3))))))
          (appendo '(c d) '(e f) z)
          ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
          ;;(== '(c d e f) z)
          ;;
          ))
     x))
  '(((c d _.))))

(test "seems-broken-11c"
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
          (appendo '(c d) '(e f) z)
          ;; seems broken: uncommenting (== '(c d e f) z) makes a failing query succeed
          ;;(== '(c d e f) z)
          ;;
          ))
     x))
  '(((c d e f))))





(test "simple-1"
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
          (fresh (w)
            (let ((y (cons 'd '())))            
              (== y w)
              (appendo '(a b c) w z)))))
     x))
  '(((a b c d))))

(test "simple-2"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            ;; change l2 to l3 in the recursion
                            (appendo d l3 l3))))))
          (fresh (w)
            (let ((y (cons 'd '())))            
              (== y w)
              (appendo '(a b c) w z)))))
     x))
  '(((a b c _.))))

(test "simple-3"
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
          (fresh (w)
            (let ((y (cons 'd '())))            
              (== y w)
              (appendo '(a b c) w z)))))
     '((a b c d))))
  '(_.0))

(test "simple-4"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            ;; change l2 to l3 in the recursion
                            (appendo d l3 l3))))))
          (fresh (w)
            (let ((y (cons 'd '())))            
              (== y w)
              (appendo '(a b c) w z)))))
     '((a b c d))))
  '())

(test "let-0"
  (run* (x)
    (eval-programo
     `(run* (z)
        (let ((y (cons 'cat 'dog)))
          (== 5 z)))
     x))
  '((5)))

(test "let-1"
  (run* (x)
    (eval-programo
     `(run* (z)
        (let ((y (cons 'cat 'dog)))
          (== y z)))
     x))
  '(((cat . dog))))


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

;; run 6 seems to diverge
(test "letrec-append-3"
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
  '((() (1 2 3 4))
    ((1 2 3 4) ())
    ((1) (2 3 4))
    ((1 2) (3 4))
    ((1 2 3) (4))))


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

(test "1e"
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
  '(((1 2 3 4))))

(test "2"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (,x (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (appendo '(1 2) '(3 4) '(1 2 3 4))))
     '((_.))))
  '(==))

(test "3"
  (run 1 (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a ,x) l)
                            (appendo d l2 l3))))))
          (appendo '(1 2) '(3 4) '(1 2 3 4))))
     '((_.))))
  '(l3))

(test "3b"
  (run* (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() l1) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (,x d l2 l3))))))
          (appendo '(1 2) '(3 4) '(1 2 3 4))))
     '((_.))))
  '(appendo))

(test "3c"
  (run 1 (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         ((== '() ,x) (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (appendo '(1 2) '(3 4) z)))
     '((1 2 3 4))))
  '(l1))

(test "3d"
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
          (appendo '(1 2) '(3 4) z)))
     '((1 2 3 4))))
  '((() l1)))

(test "3e"
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
  '((() l1)))

#|
(test "3f"
  (run 1 (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((appendo (l1 l2 l)
                       (conde
                         (,x (== l2 l))
                         ((fresh (a d l3)
                            (== (cons a d) l1)
                            (== (cons a l3) l)
                            (appendo d l2 l3))))))
          (appendo '() '() '())
          (appendo '(a) '(b) '(a b))
          (appendo '(1 2) '(3 4) z)))
     '((1 2 3 4))))
  '((() l1)))
|#

(test "4"
  (run 1 (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((five (f)
                       (== 5 f)))
          (five z)))
     x))
  '((5)))

; Don't get what we expect when all examples are internally ground
(test "5"
  (run 1 (e1 e2)
    (eval-programo
     `(run* (z)
        (letrec-rel ((five (f)
                       (== ,e1 ,e2)))
          (five 5)))
     '((_.))))
  '(((_.0 _.0) (num _.0))))

; Aha!
(test "6"
  (run 1 (x)
    (eval-programo
     `(run* (z)
        (letrec-rel ((five (f)
                       (== 7 7)))
          (five 5)))
     x))
  '(((_.))))

(test "7"
  (run 3 (e1 e2)
    (eval-programo
     `(run* (z)
        (letrec-rel ((five (f)
                       (== ,e1 ,e2)))
          (five 5)))
     '((_.))))
  '(((_.0 _.0) (num _.0))
    (() ())
    (5 f)))

(test "8"
  (run 1 (e1 e2)
    (eval-programo
     `(run* (z)
        (letrec-rel ((five (f)
                       (== ,e1 ,e2)))
          (five z)))
     '(5)))
  '((5 f)))

; External grounding, extra examples to avoid overfitting, and with symbolo to
; fasten queries
(test "9c"
  (time
    (run 1 (x y w)
      (symbolo x)
      (symbolo y)
      (symbolo w)
      (eval-programo
       `(run* (z)
          (letrec-rel ((appendo (l1 l2 l)
                         (conde
                           ((== '() l1) (== l2 l))
                           ((fresh (a d l3)
                              (== (cons a d) l1)
                              (== (cons a l3) l)
                              (appendo ,x ,y ,w))))))
            (appendo '(cat dog) '() '(cat dog))
            (appendo '(apple) '(peach) '(apple peach))
            (appendo '(1 2) '(3 4) z)))
       '((1 2 3 4)))))
  '((d l2 l3)))

; Thanks for the example, @bollu!
(test "10b"
  (run* (count)
    (eval-programo
     `(run ,count (z)
        (conde
          ((== z 1))
          ((== z 2))))
     '(1 2)))
  '(((())) (((_.0)) (=/= ((_.0 ()))))))

(test "11b"
  (run* (count answers)
    (eval-programo `(run ,count (z)
                      (conde
                        ((== z 1))
                        ((== z 2))))
                   answers))
  '((() ())
    ((()) (1))
    (((())) (1 2))
    ((((_.0)) (1 2))
     (=/= ((_.0 ()))))))
