<Cabbage> bounds(0, 0, 0, 0)
form caption("Granulor") bundle("Bundle"), size(700,450), guiMode("queue"), pluginId("def1")

image bounds(0, -466, 700, 916) channel("background") file("swirl.png")

soundfiler bounds(  5,  5,690,140), channel("beg","len"), channel("filer1"),  colour(0, 255, 255, 255), fontColour(160, 160, 160, 255)
image      bounds(  5,  5,  1,140), colour(150,150,160), shape("sharp"), identChannel("Scrubber")

image bounds(8, 156, 1029, 185), colour(0, 0, 0, 0), plant("controls") channel("image7")
filebutton bounds(10, 162, 76, 23), text("Open File", "Open File"),  channel("filename"), shape("ellipse")
checkbox   bounds(8, 198, 87, 23), channel("PlayStop"), text("Play/Stop"), , fontColour:0(255, 255, 255, 255), fontColour:1(255, 255, 255, 255)
}

rslider    bounds(132, 242, 70, 70), channel("Amp"),    range(0, 1, 0.01, 0.5, 0.001), text("amp"), $SliderStyleI textColour(255, 255, 255, 255)
rslider    bounds(232, 242, 70, 70), channel("Speed"),    range(0, 100, 0.01, 0.5, 0.001), text("speed"), $SliderStyleI textColour(255, 255, 255, 255)
rslider    bounds(466, 238, 73, 70), channel("Grainrate"), text("Grainrate"), range(0.01, 100, 0.05, 0.5, 0.0001), $SliderStyleK textColour(255, 255, 255, 255)
rslider    bounds(366, 238, 76, 70), channel("Grainsize"),    range(0.01, 1000, 0.05, 0.5, 0.001), text("Grainsize"), $SliderStyleI textColour(255, 255, 255, 255)
rslider    bounds(564, 238, 70, 70), channel("PosRand"),    range(0.01, 1000, 0.05, 0.5, 0.001), text("Pos.Rand"), $SliderStyleI textColour(255, 255, 255, 255)
rslider    bounds(132, 354, 70, 70), channel("Transpose"),    range(0, 100, 0.01, 0.5, 0.001), text("transpose"), $SliderStyleI textColour(255, 255, 255, 255)
rslider    bounds(234, 354, 70, 70), channel("Centrand"),    range(0, 100, 0.01, 0.5, 0.001), text("cent.rand"), $SliderStyleI textColour(255, 255, 255, 255)

groupbox bounds(356, 200, 288, 122) channel("groupbox10012") colour(255, 255, 255, 0) text("Grain Control") fontColour(255, 255, 255, 255)
groupbox bounds(126, 200, 190, 121) channel("groupbox10013") colour(35, 35, 35, 0) text("Sample Control") fontColour(255, 255, 255, 255)
groupbox bounds(126, 326, 193, 116) channel("groupbox10014") colour(35, 35, 35, 0) text("Pitch Control") fontColour(255, 255, 255, 255)
</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-n -d -+rtmidi=NULL -M0 --midi-key-cps=4 --midi-velocity-amp=5
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1


opcode FileNameFromPath,S,S        ; Extract a file name (as a string) from a full path (also as a string)
 Ssrc    xin                ; Read in the file path string
 icnt    strlen    Ssrc            ; Get the length of the file path string
 LOOP:                    ; Loop back to here when checking for a backslash
 iasc    strchar Ssrc, icnt        ; Read ascii value of current letter for checking
 if iasc==92 igoto ESCAPE        ; If it is a backslash, escape from loop
 loop_gt    icnt,1,0,LOOP        ; Loop back and decrement counter which is also used as an index into the string
 ESCAPE:                ; Escape point once the backslash has been found
 Sname    strsub Ssrc, icnt+1, -1        ; Create a new string of just the file name
    xout    Sname            ; Send it back to the caller instrument
endop


instr 1
gkPlayStop    chnget    "PlayStop"        ; read in widgets
 gkloop        chnget    "loop"
 gkreverse    chnget    "reverse"
 gklevel    chnget    "level"
 gSfilepath    chnget    "filename"        ; read in file path string from filebutton widget
 gkinterp    chnget    "interp"
 ga2dratio chnget "a2dratio"
 
 if changed:k(gSfilepath)==1 then        ; call instrument to update waveform viewer  
  event "i",99,0,0
 endif
 
 ktrig        trigger    gkPlayStop,0.5,0    ; if play/stop button toggles from low (0) to high (1) generate a '1' trigger
 schedkwhen    ktrig,0,0,2,0,-1        ; start instrument 2
 
endin

instr    99
 Smessage sprintfk "file(%s)", gSfilepath            ; print sound file image to fileplayer

 cabbageSet "filer1", Smessage

 /* write file name to GUI */
 Sname FileNameFromPath    gSfilepath                ; Call UDO to extract file name from the full path
 Smessage sprintfk "text(%s)",Sname                ; create string to update text() identifier for label widget
 chnset Smessage, "stringbox"                    ; send string to  widget

endin

instr    2

 if gkPlayStop==0 then                ; if play/stop is off (stop)...
  turnoff                    ; turn off this instrument
 endif                        

  iFileLen    filelen    gSfilepath        ; derive chosen sound file length
  iNChns    filenchnls    gSfilepath    ; derive the number of channels (mono=1 / stereo=2) from the chosen  sound file
  iloop    chnget    "loop"                ; read in 'loop mode' widget
  ktrig    changed    gkloop,gkinterp            ; if loop setting or interpolation mode setting

; Find the position of the last slash or backslash
iLastSlashPos = strrindex(gSfilepath, "/")
iLastBackslashPos = strrindex(gSfilepath, "\\")

; Choose the larger position to account for both forward and backward slashes
iLastPos = max(iLastSlashPos, iLastBackslashPos)

; Extract the file name
SFileName = gSfilepath;//strsub(gSfilepath, iLastPos + 1, strlen(gSfilepath))

ginFile ftgen 0, 0 ,0 ,1, SFileName, 0, 0, 0; sound source file 
giSine ftgen 0,0,65536,10,1
giCosine ftgen 0,0,8193,9,1,1,90
giSigmoRise ftgen 0,0,8193,19,0.5,1,270,1
giSigmoFall ftgen 0,0,8193,19,0.5,1,90,1
giPan		ftgen	0, 0, 32768, -21, 1		; for panning (random values between 0 and 1)

gkamp chnget "Amp"
gkspeed chnget "Speed"
gkgrainrate chnget "Grainrate";p5; 
gkgrainsize chnget "Grainsize";p6;
gkcent chnget "Transpose"; p7 transpositionin cent
gkposrand chnget "PosRand" ;p8 ; time position randomness (offset) of the pointer in ms
gkcentrand chnget "Centrand";  p9 transposition randomness in cents
ipan = 0;p10; panning narrow(0) to wide(1) 
idist			= 0.5;p11		; grain distribution (0=periodic, 1=scattered)

/* get lentgh of audio file for transposition and time pointer*/
ifilen tableng ginFile
ifildur = ifilen / sr

/*sync input*/
async = 0.0; disable external sync 

/*grain envelope*/
kenv2amt = 0;no secondary enveloping
ienv2tab = -1; default secondary envelope
ienv_attack = giSigmoRise;  attack envelope
ienv_decay = giSigmoFall; decay envelope
ksustain_amount = 0; time(infraction of grain duration) as sustain level for each  grain.
ka2dratio = 0.5; balance between attack and decay

/*amplitude*/
igainmask = -1; no gain masking 

/*transposition*/
gkcentrand rand gkcentrand; random transposition
iorig = 1/ ifildur; original pitch
kwavfreq = iorig * cent(gkcent + gkcentrand)

/*other pitch related params(disabled)*/
ksweepshape =0 ; no frequency sweep
iwavfreqstarttab = -1; default frequency sweep start
iwavfreqendtab = -1; default frequency sweep
awavfm = 0; no FM input
ifmamptab = -1; default FM scaling (=-1)
kfmenv = -1 ; default FM envelope(flat)

/*trainlet related params(disabled)*/
icosine = giCosine; cosine ftable
kTrainCps = gkgrainrate; set trainlet cps equal to grain rate for single-cycle trainlet in each grain 
knumpartials = 1; number of partials in trainlet
kchroma  = 1; 

/*pannings, using channel mask*/
imid = .5; center
ileftmost = imid - ipan/2
irightmost = imid + ipan/2
giPanthis ftgen 0, 0, 32768, -24, giPan, ileftmost, irightmost; reScales gipan according to ipan
			tableiw  0, 0, giPanthis; change index 0
			tableiw 32766, 1, giPanthis; and 1 for ichannelmasks
ichannelmasks = giPanthis; ftable for panning

/*random gain masking (disabled)*/
krandommask = 0;

/*source waveforms*/
kwaveform1		= ginFile	; source waveform
kwaveform2		= ginFile	; all 4 sources are the same
kwaveform3		= ginFile
kwaveform4		= ginFile
iwaveamptab		= -1		; (default) equal mix of source waveforms and no amplitude for trainlets

/*timepointers*/ 
afilposphas phasor gkspeed / ifildur

/*generate random deviaton of the time pointer*/
gkposrandsec = gkposrand / 1000 ; ms -> sec
gkposrand = gkposrandsec / ifildur ; phase value (0-1)
gkrndpos linrand gkposrand; ranodm offset in phase values

/*add random deviation to the time pointer*/
asamplepos1		= afilposphas + gkrndpos; resulting phase values (0-1)
asamplepos2		= asamplepos1
asamplepos3		= asamplepos1	
asamplepos4		= asamplepos1

/*original key for each source waveform*/
kwavekey1		= 1
kwavekey2		= kwavekey1	
kwavekey3		= kwavekey1
kwavekey4		= kwavekey1

/* maximum number of grains per k-period*/
imax_grains		= 100	

aL, aR partikkel gkgrainrate, idist, -1, async, kenv2amt, ienv2tab, ienv_attack, ienv_decay,
		ksustain_amount, ka2dratio, gkgrainsize, gkamp, igainmask, kwavfreq,ksweepshape, 
		iwavfreqstarttab, iwavfreqendtab, awavfm, ifmamptab,kfmenv,icosine, kTrainCps,
		knumpartials, kchroma, ichannelmasks, krandommask,  kwaveform1, kwaveform2,
		kwaveform3, kwaveform4,iwaveamptab, asamplepos1, asamplepos2, asamplepos3,
		asamplepos4,kwavekey1, kwavekey2, kwavekey3, kwavekey4, imax_grains
	
outs aL, aR


endin




</CsInstruments>
<CsScore>
;causes Csound to run for about 7000 years...
i1 0 z
e
</CsScore>
</CsoundSynthesizer>








<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>0</y>
 <width>0</width>
 <height>0</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="background">
  <r>240</r>
  <g>240</g>
  <b>240</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
