Chez Scheme Version 10.0.0
Copyright 1984-2024 Cisco Systems, Inc.

> (load "talk-meta.scm")
> (run* (x)
  (eval-programo
   `(run* (z)
      (conde
        ((== 'cat z))
        ((== 'dog z))))
   x))
((cat dog))
> (run 1 (x)
  (eval-programo
   `(run* (z)
      (conde
        ((== ',x z))
        ((== 'dog z))))
   '(cat dog)))
(cat)
> (run* (x)
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
(((1 2 3 4)))
> (load "talk-combined.scm")
> (run 5 (x y)
  (eval-programo
   `(run* (z)
      (letrec-func ((append (l s)
                      (if (null? l)
                          s
                          (cons (car l) (append (cdr l) s)))))
        (== (append '(a b c) '(d e)) z)
        (== (append ',x ',y) '(1 2 3 4))))
   '((a b c d e))))
((() (1 2 3 4))
  ((1 2 3 4) ())
  ((1) (2 3 4))
  ((1 2) (3 4))
  ((1 2 3) (4)))
> (run 1 (v w x y)
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
((l cons appendo append))
> 