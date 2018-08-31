/*

Live interface for the acousmatic sound distribution of the piece 'DAF342wregsf'
from 'States of Emergency' by Mads Kjeldgaard. The piece was originally released
on Conditional Records in 2018: http://shop.conditional.club/album/states-of-emergency

This script is to be used with the Korg NanoKontrol2 midi controller

More info: https://madskjeldgaard.dk

*/


(
var acousmatic_daf342 = {
    var sendOSCData = true;
    var basepath = "~/scripts/sc/daf342_acousmatic/";
    var soundfileBuffer = Buffer.read(s, basepath ++ "snd/DAF342_LIVE_VERSION2496.wav".standardizePath);

    (

    init: {|self| 

        // Load synths
        (basepath ++ "daf342_acousmatic_interface_synths.scd").load;
        
        self.setupController; 

        self.setupBusses;

        // Set defaults for fader positions
        self.controlBusses.faders.at(0).set(1.0); // Playback rate
        self.controlBusses.faders.at(1).set(1.0); // LPF
        self.controlBusses.faders.at(2).set(1.0); // HPF

        // Send amplitude data over OSC 
        self.sendAnalysisData;

        "Ready 2 play: DAF342wregsf".postln;
    },

    sendAnalysisData: {|self|
        fork{
            loop{
                var waittime=0.1;

                self.analysis.amp.get({|val|
                    self.oscSender("/amplitude", val);
                });
                
                self.analysis.loAmp.get({|val|
                    self.oscSender("/lowAmplitude", val);
                });
                
                self.analysis.hiAmp.get({|val|
                    self.oscSender("/highAmplitude", val);
                });

                waittime.wait; 
            }
        };
    },

    patch: {|self| 

		/*
			MAPPINGS

			Knob1: Gain
			Knob2: EQ Low boost 
			Knob3: EQ Hi boost
			Knob4: Sub freq
			Knob5: Granular feedback + chaos
			Knob6: Amount of shift
			Knob7: Reverb time
			Knob8: Reverb modDepth

			Fader1: Playback rate
			Fader2: LPF
			Fader3: HPF
			Fader4: Sub
			Fader5: Grains
			Fader6: Pitchshift dry/wet
			Fader7: Reverb dry/wet
			Fader9: Size

		*/

        var namebase = 'daf342_';

        self.synthgroup = Group.new; 

        // Patch synths and put them in a bundle
        // Busses are implicitly patched

        s.makeBundle(nil, { 

            // SOURCE
            Synth.head(self.synthgroup, 
                namebase ++ 'diskin', 
                [
                'buf', soundfileBuffer,
                'gain', self.controlBusses.knobs.at(0).asMap,
                'rate', self.controlBusses.faders.at(0).asMap,
                'trigger', 1
                ]
            );
            
            // EFFECTS
            Synth.tail(self.synthgroup, 
                namebase ++ 'lpf', 
                [
                'cutoff', self.controlBusses.faders.at(1).asMap
                ]
            );

            Synth.tail(self.synthgroup, 
                namebase ++ 'hpf', 
                [
                'cutoff', self.controlBusses.faders.at(2).asMap
                ]
            );
            
            Synth.tail(self.synthgroup, 
                namebase ++ 'grain', 
                [
                'drywet', self.controlBusses.faders.at(4).asMap,
                'grainsize', self.controlBusses.faders.at(4).asMap,
                'grainrand', self.controlBusses.knobs.at(4).asMap,
                'fbGain', self.controlBusses.knobs.at(4).asMap
                ]
            );

           Synth.tail(self.synthgroup, 
                namebase ++ 'pitchshift', 
                [
                'drywet', self.controlBusses.faders.at(5).asMap,
                'shift', self.controlBusses.knobs.at(5).asMap
                ]
            );

            /*     namebase ++ 'waveloss', */ 
            /*     [ */
            /*     'drywet', self.controlBusses.faders.at(5).asMap, */
            /*     'loss', self.controlBusses.knobs.at(5).asMap */
            /*     ] */
            /* ); */
            
            
            Synth.tail(self.synthgroup, 
                namebase ++ 'eq', 
                [
                'q', 1,
                'loBoost', self.controlBusses.knobs.at(1).asMap,
                'hiBoost', self.controlBusses.knobs.at(2).asMap
                ]
            );
            
            Synth.tail(self.synthgroup, 
                namebase ++ 'comp', 
                [
                'slopeBelow', 0.6
                ]
            );
            
            // ANALYSIS
            Synth.tail(self.synthgroup, 
                namebase ++ 'amp', 
                [
                'outbus', self.analysis.amp
                ]
            );
            
            Synth.tail(self.synthgroup, 
                namebase ++ 'low_amp', 
                [
                'outbus', self.analysis.loAmp
                ]
            );
            
            Synth.tail(self.synthgroup, 
                namebase ++ 'high_amp', 
                [
                'outbus', self.analysis.hiAmp
                ]
            );

            Synth.tail(self.synthgroup, 
                namebase ++ 'sub', 
                [
                'subamp', self.analysis.amp.asMap,
                'drywet', self.controlBusses.faders.at(3).asMap,
                'freq', self.controlBusses.knobs.at(3).asMap,
                ]
            );

            // VERB
            Synth.tail(self.synthgroup, 
                namebase ++ 'verb', 
                [
                'drywet', self.controlBusses.faders.at(6).asMap,
                'time', self.controlBusses.knobs.at(6).asMap,
                'modDepth', self.controlBusses.knobs.at(7).asMap,
                'size', self.controlBusses.faders.at(7).asMap
                ]
            );
            
            // OUTPUT
            Synth.tail(self.synthgroup, 
                namebase ++ 'out'
            );
        });
    },

    setupBusses: {|self|

        var defaultKnobValue = 0.0;
        var defaultFaderValue = 0.0;

        self.controlBusses = ();
        
        self.analysis = ();
        self.analysis.amp = Bus.control(s,1);
        self.analysis.hiAmp = Bus.control(s,1);
        self.analysis.loAmp = Bus.control(s,1);


        // Create fader value busses
        self.controlBusses.faders = Array.fill(8,
            {Bus.control(s,1).set(defaultFaderValue)}
        );
        
        // Create value busses
        self.controlBusses.knobs = Array.fill(8, 
            {Bus.control(s,1).set(defaultKnobValue)}
        );

        // Create value busses
        self.controlBusses.rBtns = Array.fill(8, {Bus.control(s,1)});
        
        // Create value busses
        self.controlBusses.mBtns = Array.fill(8, {Bus.control(s,1)});

    },

    setupController: {|self| 
        var synths;
        
        n = NanoKontrol2();

        // FADERS
        n.faders.do{|fader, i | 
            fader.onChange = {|fadervalue| 
                self.controlBusses.faders.at(i).set(fadervalue/128);
                self.oscSender("/fader" ++ i, fadervalue/128);
            }
        };

        // KNOBS
        n.knobs.do{|knob, i | 
            knob.onChange = {|knobvalue| 
                self.controlBusses.knobs.at(i).set(knobvalue/128);
                self.oscSender("/knob" ++ i, knobvalue/128);
            }
        };
		
        // RBUTTONS
        n.rBtns.do {|rBtn, i|
			rBtn.onChange = {|val|
			self.controlBusses.rBtns.at(i).set(val/128);
    		}
		};
        
        // MBUTTONS
		n.mBtns.do {|mBtn, i|
			mBtn.onChange = {|val|
			self.controlBusses.mBtns.at(i).set(val/128);
    		}
		};
        
        // TRANSPORT
        n.playBtn.onPress = {|val| 
            self.controlBusses.stopPlay.set(1);
            "Play button pressed".postln;

            self.patch;
            self.oscSender("/playButton", "pressed!");
        };

        n.stopBtn.onPress = {|val| 
            self.controlBusses.stopPlay.set(0);
            "Stop button pressed".postln;
            s.stopRecording;
            self.synthgroup.free;
        };

        n.recBtn.onPress = {|val| 
            "Rec button pressed".postln;
            s.record;
        };


    },

    oscTarget: {|self, targetAddress="127.0.0.1", targetPort=8000| 
        NetAddr.new(targetAddress, targetPort);
    },	

	oscSender: {|self, message, parameter, base="/daf342"|
        if (sendOSCData, {
            self.oscTarget.sendMsg(base ++ message, parameter);   
        }, 
        {"Not sending OSC data"})
	}

)};


acousmatic_daf342.value.init;
)
