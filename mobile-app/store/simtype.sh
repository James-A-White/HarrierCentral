#!/bin/zsh
# simtype.sh "text" — type into the focused Simulator field. Uses macOS virtual
# keycodes (the Simulator ignores unicode-string key events). ASCII letters,
# digits, space, . , - = and newline (\n) supported.
DIR=${0:A:h}; source "$DIR/simenv.sh"
"$PY" - "$1" <<'PY'
import sys, time, Quartz
K={'a':0,'s':1,'d':2,'f':3,'h':4,'g':5,'z':6,'x':7,'c':8,'v':9,'b':11,'q':12,'w':13,'e':14,'r':15,'y':16,'t':17,
   '1':18,'2':19,'3':20,'4':21,'6':22,'5':23,'=':24,'9':25,'7':26,'-':27,'8':28,'0':29,'o':31,'u':32,'i':34,'p':35,
   'l':37,'j':38,'k':40,'n':45,'m':46,' ':49,'\n':36,'.':47,',':43}
for ch in sys.argv[1]:
    code = K[ch.lower()]
    for down in (True, False):
        e = Quartz.CGEventCreateKeyboardEvent(None, code, down)
        if ch.isupper(): Quartz.CGEventSetFlags(e, Quartz.kCGEventFlagMaskShift)
        Quartz.CGEventPost(Quartz.kCGHIDEventTap, e)
    time.sleep(0.05)
PY
