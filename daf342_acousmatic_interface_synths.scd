(
    /*
     
    - ADD SPECTRAL FREEZE ? 
    - ADD LAGTIME ! ! ! !

    */ 

var basename = 'daf342_';
var numChans = 2;
var lagtime = 0.1;

SynthDef(basename ++ 'amp', {|envatt = 0.01, envrel = 0.01, bus, outbus| 

    var sig = In.ar(bus, numChans).sum;

    sig = Amplitude.kr(sig, envatt, envrel);

    Out.kr(outbus, sig);

}, lagtime.dup(2)).add;

SynthDef(basename ++ 'low_amp', {|envatt = 0.01, envrel = 0.01, bus, outbus| 

    var sig = In.ar(bus, numChans).sum;

    sig = LPF.ar(sig, 250); 

    sig = Amplitude.kr(sig, envatt, envrel);

    Out.kr(outbus, sig);

}, lagtime.dup(2)).add;

SynthDef(basename ++ 'high_amp', {|envatt = 0.01, envrel = 0.01, bus, outbus| 

    var sig = In.ar(bus, numChans).sum;

    sig = HPF.ar(sig, 1500); 

    sig = Amplitude.kr(sig, envatt, envrel);

    Out.kr(outbus, sig);

}, lagtime.dup(2)).add;


SynthDef(basename ++ 'diskin', {|gain = 1, rate = 1, trigger = 1, amp = 1, buf, bus|

        var sig = PlayBuf.ar(numChans, 
            buf, 
            BufRateScale.kr(buf) * rate.linlin(0.0, 1.0, 0.01, 1.05), 
            trigger, 
            0, 
            0, 
            doneAction: 2
        );

        Out.ar(bus, sig * gain.linlin(0.0, 1.0, 1.0, 1.5));
}, lagtime.dup(4)).add;

SynthDef(basename ++ 'lpf' , {|cutoff = 1, bus| 

    var sig = LPF.ar(In.ar(bus, numChans), cutoff.linexp(0.0, 1.0, 40, 20000));

    ReplaceOut.ar(bus, sig)
}, lagtime).add;

SynthDef(basename ++ 'hpf' , {|cutoff = 1, bus| 

    var sig = HPF.ar(In.ar(bus, numChans), cutoff.linexp(0.0, 1.0, 20000, 40));

    ReplaceOut.ar(bus, sig)
}, lagtime).add;

SynthDef(basename ++ 'comp' , {|slopeBelow = 1, bus| 

    var sig = In.ar(bus, numChans);

    sig =  Compander.ar(sig, sig,
        thresh: 0.9,
        slopeBelow: slopeBelow,
        slopeAbove: 0.5, // Ratio, 1/3 == 3: 1
        clampTime:  0.01,
        relaxTime:  0.1
    );

    ReplaceOut.ar(bus, sig)
}, lagtime).add;

SynthDef(basename ++ 'eq' , {|loBoost = 0, hiBoost = 0, q = 0.3, hiFreq = 3000,  loFreq = 250, bus| 

    var sig = In.ar(bus, numChans);

    sig = MidEQ.ar(sig, loFreq, q.linlin(0.0, 1.0, 0.1, 1.0), loBoost.linlin(0.0, 1.0, - 12.0, 12.0));

    sig = MidEQ.ar(sig, hiFreq, q.linlin(0.0, 1.0, 0.1, 1.0), hiBoost.linlin(0.0, 1.0, - 12.0, 12.0));

    ReplaceOut.ar(bus, sig)

}, lagtime.dup(5)).add;

SynthDef(basename ++ 'waveloss' , {|drywet = 0, loss = 1, bus| 

    var in = In.ar(bus, numChans);

    var sig =  WaveLoss.ar(in, drop: loss.linlin(0.0, 1.0, 0, 10), outof: 10, mode: 2); 

    XOut.ar(bus, drywet, sig)

}, lagtime.dup(2)).add;

SynthDef(basename ++ 'spectralfun' , {|drywet = 0, stretch = 1, shift = 8, bus| 

    var in = In.ar(bus, numChans);

	var chain = FFT(LocalBuf(2048) ! 2, in);

	var sig;

	chain = PV_MagSmear(chain, shift.linlin(0.0, 1.0, 0, 50)); 

	sig = IFFT(chain) ! 2 * 3;

    XOut.ar(bus, drywet, sig)

}, lagtime.dup(3)).add;

SynthDef(basename ++ 'freqshift' , {|drywet = 0, freq = 0.5, bus| 

    var in = In.ar(bus, numChans);

    var sig = FreqShift.ar(in, freq: freq.linexp(0.0, 1.0, 40, 4000), phase: 0);
     
    XOut.ar(bus, drywet, sig)

}, lagtime.dup(2)).add;

SynthDef(basename ++ 'verb', {|time = 1, size = 1, drywet = 0, modDepth = 0.1, bus| 

    var sig = In.ar(bus, numChans);

    sig = JPverb.ar(sig, t60: time,    
        damp: 1 - drywet, 
        size: size.linlin(0.0, 1.0, 0.1, 5.0), 
        earlyDiff: modDepth.linlin(0.0, 1.0, 1.0, 0.5), 
        modDepth: modDepth.linlin(0.0, 1.0, 0.01, 1.0), 
        modFreq: 2, 
        lowcut: 500, highcut: 2000);

    /* sig = Greyhole.ar(sig, */ 
    /*     delayTime: time.linlin(0.0, 1.0, 0.01, 12.0), */ 
    /*     damp: 0, */ 
    /*     size: size.linlin(0.0, 1.0, 0.1, 3.0), */ 
    /*     diff: 0.807, */ 
    /*     feedback: modDepth, */ 
    /*     modDepth: modDepth, */  
    /*     modFreq: 2); */

    XOut.ar(bus, drywet, sig);
}, lagtime.dup(4)).add;

SynthDef(basename ++ 'freeze', {|drywet = 0, freeze = 1, bus| 

    var dry = In.ar(bus, numChans);
    var sig;
    var chain = FFT(LocalBuf(2048, numChans), dry);

    chain = PV_Freeze(chain, freeze);

	sig = IFFT(chain);

    XOut.ar(bus, drywet, Splay.ar([ dry, sig ! 2 ]));
}, lagtime.dup(2)).add;

SynthDef(basename ++ 'sub', {|freq = 0.5, subamp, drywet = 0, bus| 

    var dry = In.ar(bus, numChans);

    var sig = SinOsc.ar(freq.linlin(0.0, 1.0, 40, 120), 
        0, 
        (subamp * 4).clip(0, 1)
    );

    sig = LPF.ar(sig, 150);

    sig = dry + sig; 

    sig = LeakDC.ar(sig);

    XOut.ar(bus, drywet, sig);
}, lagtime.dup(3)).add;


SynthDef(basename ++ 'grain', {|grainsize = 0.25, grainrand = 0.8, drywet = 1, fbGain = 0, bus|
        var input = In.ar(bus, numChans);

        var bufLength = 1.0;
        var localBuf = LocalBuf(bufLength * SampleRate.ir, numChans).clear;

        var warp = Warp1.ar(
            numChans,
            localBuf,
            LFSaw.ar(1/bufLength).range(0, 1),
            Drand([ 2, - 2 ], inf),
            grainsize.linlin(0.0, 1.0, 2.0, 0.31),
            - 1,
            2,
            grainrand.linlin(0.0, 1.0, 0.2, 1.0),
            4
        );

        // record w/ feedback
        RecordBuf.ar(tanh(input + HPF.ar(tanh(warp * fbGain), 30)), localBuf);
        
        warp = warp.tanh;
        warp = HPF.ar(warp * 0.5, 150);
        warp = warp.sanitize;

        XOut.ar(bus, drywet, warp);

}, lagtime.dup(4)).add;

SynthDef(basename ++ 'pitchshift', {|drywet = 0, shift = 1, size = 0.2, bus| 

    var dry = In.ar(bus, numChans);
    var sig;

    sig = PitchShift.ar(in: dry, 
        windowSize: 0.25, //drywet.linlin(0.0, 1.0, 0.01, 0.4), 
        pitchRatio: shift.linlin(0.0, 1.0, 0.01, 2.0),
        pitchDispersion: drywet.linlin(0.0, 1.0, 0.1, 1.0), 
        timeDispersion: 0);

    XOut.ar(bus, drywet, sig);
}, lagtime.dup(3)).add;


SynthDef(basename ++ 'out', {|bus| 

	var in = In.ar(bus, numChans); 

	// apply limiter 
    var sig = Compander.ar(in, in,
        thresh: 0.75, 
        slopeBelow: 1,
        slopeAbove: 0.1,
        clampTime:  0.01,
        relaxTime:  0.01
    );

    ReplaceOut.ar(0, sig * 0.5) 
}).add;

)
