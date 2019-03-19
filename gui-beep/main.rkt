#lang racket

(require racket/gui)

; Helpers

(define *min-position* 0)
(define *max-position* 2000)
(define *min-frequency* 1)
(define *max-frequency* 19999)

(define min-freq (log *min-frequency*))
(define max-freq (log *max-frequency*))
(define frequency-scale (/ (- max-freq min-freq) (- *max-position* *min-position*)))
; Convert slider position to frequency
(define (position->frequency position)
  (inexact->exact (round
    (exp (+ min-freq (* frequency-scale (- position *min-position*)))))))
; Convert frequency to slider position
(define (frequency->position freq)
  (inexact->exact (round
    (/ (- (log freq) min-freq) (+ frequency-scale *min-position*)))))

(define notes (hash "A" 440.00
                    "B" 493.88
                    "C" 261.63
                    "D" 293.66
                    "E" 329.63
                    "F" 349.23
                    "G" 292.00))

; Callbacks

(define (adjust-frequency widget event)
  (send frequency-field set-value
    (~a (position->frequency (send widget get-value)))))

(define (adjust-slider entry event)
  (define new-freq (string->number (send entry get-value)))
  (send slider set-value
        (frequency->position (if new-freq new-freq *min-frequency*))))

(define (set-frequency freq)
  (send slider set-value (frequency->position freq))
  (send frequency-field set-value (~a freq)))

(define (adjust-octave modifier)
  (set-frequency (* (string->number (send frequency-field get-value)) modifier)))

(define (decrease-octave button event) (adjust-octave 0.5))
(define (increase-octave button event) (adjust-octave 2))

(define (set-note choice event)
  (set-frequency (hash-ref notes (send choice get-string-selection))))

(define (generate-tone button event)
  (system (format "beep -f ~a -l ~a"
                  (send frequency-field get-value)
                  (send duration-field get-value))))

; Custom GUI class

(define number-field%
  (class text-field%
    (init min-value max-value)
    (define min-allowed min-value)
    (define max-allowed max-value)
    (super-new)
    (define/override (on-focus on?)
      (unless on?
        (define current-value (string->number (send this get-value)))
        (unless (and current-value
                     (>= current-value min-allowed)
                     (<= current-value max-allowed))
          (send this set-value (~a min-allowed))
          (send slider set-value (string->number (send frequency-field get-value))))))))

; GUI Elements

(define frame (new frame% [label "Bleep"]))

(define slider (new slider% [label #f]
                           [min-value *min-position*]
                           [max-value *max-position*]
                           [parent frame]
                           [init-value (frequency->position 440)]
                           [style '(horizontal plain)]
                           [vert-margin 25]
                           [horiz-margin 10]
                           [callback adjust-frequency]))

(define frequency-pane
  (new horizontal-pane% [parent frame]
                        [border 10]
                        [alignment '(center center)]))

(define lower-button
  (new button% [parent frequency-pane]
               [label "<"]
               [callback decrease-octave]))

(define frequency-field
  (new number-field% [label #f]
                     [parent frequency-pane]
                     [init-value "440"]
                     [min-value *min-frequency*]
                     [max-value *max-frequency*]
                     [min-width 64]
                     [stretchable-width #f]
                     [callback adjust-slider]))

(define frequency-label
  (new message% [parent frequency-pane]
                [label "Hz"]))

(define higher-button
  (new button% [parent frequency-pane]
               [label ">"]
               [callback increase-octave]))

(define control-pane
  (new horizontal-pane% [parent frame]
                        [border 25]
                        [spacing 25]))

(define duration-pane (new horizontal-pane% [parent control-pane]))

(define duration-field
  (new number-field% [label "Duration"]
                     [parent duration-pane]
                     [min-value 1]
                     [max-value 600000]
                     [init-value "200"]
                     [min-width 120]))

(define note
  (new choice% [label "♪ "]
               [choices '("A" "B" "C" "D" "E" "F" "G")]
               [parent control-pane]
               [callback set-note]))

(define play-button
  (new button% [parent control-pane]
               [label "Play"]
               [callback generate-tone]))

(send frame show #t)