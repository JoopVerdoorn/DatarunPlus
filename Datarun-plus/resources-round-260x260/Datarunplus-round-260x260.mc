class DatarunplusApp extends Toybox.Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new DatarunView() ];
    }
}


class DatarunView extends Toybox.WatchUi.DataField {
	//!Get battery-status
	using Toybox.System as Sys;
	using Toybox.Lang;
	var stats = Sys.getSystemStats();
	var pwr = stats.battery;


	//!Get device info
	var mySettings = System.getDeviceSettings();
	var screenWidth = mySettings.screenWidth;
	var screenShape = mySettings.screenShape;
	var screenHeight = mySettings.screenHeight;
	var distanceUnits = mySettings.distanceUnits;
	var watchType = mySettings.partNumber;
	var is24Hour = mySettings.is24Hour;   //!boolean
	var isTouchScreen = mySettings.isTouchScreen;  //!boolean
	var numberis24Hour = 0;
	var numberisTouchScreen = 0;

	hidden var uNoAlerts = false;
	hidden var uRequiredPower		 		= "000:999";
    hidden var uWarningFreq = 5; 
	hidden var vibrateseconds = 0;
    
    hidden var uHrZones                     = [ 93, 111, 130, 148, 167, 185 ];
    hidden var unitP                        = 1000.0;
    hidden var unitD                        = 1000.0;
    var Pace1 								= 0;
    var Pace2 								= 0;
    var Pace3 								= 0;
	var Pace4 								= 0;
    var Pace5 								= 0;
    var mETA								= 0;
        
    hidden var uTimerDisplay                = 0;
    //! 0 => Timer
    //! 1 => Lap time
    //! 2 => Last lap time
    //! 3 => Average lap time

    hidden var uDistDisplay                 = 0;
    //! 0 => Total distance
    //! 1 => Lap distance
    //! 2 => Last lap distance

    hidden var uHeartratefield                 = 0;
    //! 0 => Heartrate
    //! 1 => Heartrate zone
    //! 2 => No heartrate, larger pace field

    hidden var uPacefield                 = 0;
    //! 0 => Pace in minutes per km/mile
    //! 1 => Pace in seconds per 100 meter
    //! 2 => Speed in km/mile per hour
        
    hidden var uRoundedPace                 = true;
    //! true     => Show current pace as Rounded Pace (i.e. rounded to 5 second intervals)
    //! false    => Show current pace without rounding (i.e. 1-second resolution)

	hidden var uMaxColoringPace             = true;
    //! true     => Show 5 colors in pacefield in middle row (-10%<, -5%<, -5% and 5%, >5%, >10%)
    //! false    => Show 3 colors in pacefield in middle row (-5%<, -5% and 5%, >5%)

	hidden var uColoringPaceFromAver        = true;
    //! true     => Use average pace for colors in pacefield in middle row
    //! false    => Use pace based on desired finish time for colors  	

	hidden var uAveragedPace                = true;
    //! true     => Show current pace as Averaged Pace (i.e. average of the last 5 seconds)
    //! false    => Show current pace without averaging (i.e. pace at this second\)

	hidden var uBlackBackground             = true;
    //! true     => Use black background
    //! false    => Use white background

    hidden var uBacklight                   = false;
    //! true     => Force the backlight to stay on permanently
    //! false    => Use the defined backlight timeout as normal

    hidden var uShowlaps                   = false;
    //! true     => Show number of laps
    //! false    => Show current time

	hidden var uMiddlerightMetric           = 13;    //! Data to show in middle right field
    hidden var uBottomLeftMetric            = 0;    //! Data to show in bottom left field
    hidden var uBottomRightMetric           = 1;    //! Data to show in bottom right field
    //! Lower fields enum:
    //! 0 => (overall) average pace
    //! 1 => Lap pace
    //! 2 => Last lap pace
    //! 3 => Altitude
    //! 4 => Elevation gain
    //! 5 => Elevation loss
    //! 6 => ETA (finish time)
    //! 7 => Deviation from finish time
    //! 8 => Required pace for finish time
    //! 9 => Heartrate
    //! 10 => Heartrate zone
    //! 11 => Stryd footpod power
    //! 12 => Training effect
    //! 13 => Cadence (only for middle right field)
        
    //! Race distance
    hidden var uRacedistance                    = 42195;

    //! Race distance
    hidden var uRacetime							= "03:59:48";

    //! Which average pace metric should be used as the reference for deviation of the current pace? (see above)
    hidden var uTargetPaceMetric            = 0;

    //! License serial
    hidden var umyNumber                    = 0;
    
    //! Show demoscreen
    hidden var uShowDemo					= false;
    
    //! Use timer of last lap to calculate ETA
    hidden var uETAfromLap = true;
    
    hidden var mStartStopPushed             = 0;    //! Timer value when the start/stop button was last pushed

    hidden var mStoppedTime                 = 0;
    hidden var mStoppedDistance             = 0;
    hidden var mPrevElapsedDistance         = 0;

    hidden var mLaps                        = 1;
    hidden var mLastLapDistMarker           = 0;
    hidden var mLastLapTimeMarker           = 0;
    hidden var mLastLapStoppedTimeMarker    = 0;
    hidden var mLastLapStoppedDistMarker    = 0;

    hidden var mLastLapTimerTime            = 0;
    hidden var mLastLapElapsedDistance      = 0;
    hidden var mLastLapMovingSpeed          = 0;
    hidden var uAlertbeep = false;
    
    hidden var mtrainingEffect = 0;

    function initialize() {
        DataField.initialize();

        uHrZones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());


         var mApp = Application.getApp();
         uTimerDisplay       = mApp.getProperty("pTimerDisplay");
         uDistDisplay        = mApp.getProperty("pDistDisplay");
         uMiddlerightMetric   = mApp.getProperty("pMiddlerightMetric");         
         uBottomLeftMetric   = mApp.getProperty("pBottomLeftMetric");
         uBottomRightMetric  = mApp.getProperty("pBottomRightMetric");
         uRoundedPace        = mApp.getProperty("pRoundedPace");
         uMaxColoringPace    = mApp.getProperty("pMaxColoringPace");
         uColoringPaceFromAver= mApp.getProperty("pColoringPaceFromAver");
         uAveragedPace       = mApp.getProperty("pAveragedPace");
         uBlackBackground    = mApp.getProperty("pBlackBackground");
         uBacklight          = mApp.getProperty("pBacklight");
         umyNumber			 = mApp.getProperty("myNumber");
         uShowDemo			 = mApp.getProperty("pShowDemo");
         uShowlaps			 = mApp.getProperty("pShowlaps");
         uHeartratefield	 = mApp.getProperty("pHeartratefield");
         uRacedistance		 = mApp.getProperty("pRacedistance");
         uRacetime			 = mApp.getProperty("pRacetime");
         uETAfromLap		 = mApp.getProperty("pETAfromLap");
         uPacefield		 	= mApp.getProperty("pPacefield");
         uRequiredPower		 = mApp.getProperty("pRequiredPower");
         uWarningFreq		 = mApp.getProperty("pWarningFreq");
         uAlertbeep			 = mApp.getProperty("pAlertbeep");
                  
        if (uRacedistance < 1) { 
			uRacedistance 		= 42195;
		}


        if (System.getDeviceSettings().paceUnits == System.UNIT_STATUTE) {
            unitP = 1609.344;
        }

        if (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) {
            unitD = 1609.344;
        }
		uRacedistance = (unitD/1000)*uRacedistance;
    }


    //! Calculations we need to do every second even when the data field is not visible
    function compute(info) {
        //! If enabled, switch the backlight on in order to make it stay on
        if (uBacklight) {
             Attention.backlight(true);
        }
    }

    //! Store last lap quantities and set lap markers
    function onTimerLap() {
		Lapaction ();
	}

	//! Store last lap quantities and set lap markers after a step within a structured workout
	function onWorkoutStepComplete() {
		Lapaction ();
	}

    //! Timer transitions from stopped to running state
    function onTimerStart() {
        startStopPushed();
    }


    //! Timer transitions from running to stopped state
    function onTimerStop() {
        startStopPushed();
    }
    
    //! Start/stop button was pushed - emulated via timer start/stop
    function startStopPushed() {
        var info = Activity.getActivityInfo();
        var doublePressTimeMs = null;
        if ( mStartStopPushed > 0  &&  info.elapsedTime > 0 ) {
            doublePressTimeMs = info.elapsedTime - mStartStopPushed;
        }
        if ( doublePressTimeMs != null  &&  doublePressTimeMs < 5000 ) {
            uNoAlerts = !uNoAlerts;
        }
        mStartStopPushed = (info.elapsedTime != null) ? info.elapsedTime : 0;
    }

    //! Current activity is ended
    function onTimerReset() {
        mPrevElapsedDistance        = 0;

        mLaps                       = 1;
        mLastLapDistMarker          = 0;
        mLastLapTimeMarker          = 0;

        mLastLapTimerTime           = 0;
        mLastLapElapsedDistance     = 0;

        mStartStopPushed            = 0;
    }


    //! Do necessary calculations and draw fields.
    //! This will be called once a second when the data field is visible.
    function onUpdate(dc) {
        var info = Activity.getActivityInfo();
    	

    	var SPower = 0;  
   		if (info.currentPower != null) {
   			SPower = info.currentPower;
   		} 
		
		
    	//! Setup back- and foregroundcolours
        var mColour;
        var mColourFont;
		var mColourFont1;
        var mColourLine;
        var mColourBackGround;

		if (uBlackBackground == true ){
			mColourFont = Graphics.COLOR_WHITE;
			mColourFont1 = Graphics.COLOR_WHITE;
			mColourLine = Graphics.COLOR_YELLOW;
			mColourBackGround = Graphics.COLOR_BLACK;
		} else {
			mColourFont = Graphics.COLOR_BLACK;
			mColourFont1 = Graphics.COLOR_BLACK;
			mColourLine = Graphics.COLOR_RED;
			mColourBackGround = Graphics.COLOR_WHITE;
		}
		
		//! Set background color
        dc.setColor(mColourBackGround, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle (0, 0, 260, 260);
        	
    	//! Check license
		if (is24Hour == false) {
        	numberis24Hour = 51;
    	} else {
    		numberis24Hour = 23;
    	}
    	if (isTouchScreen == false) {
        	numberisTouchScreen = 87;
    	} else {
    		numberisTouchScreen = 5;
    	}
		var deviceID1 = (screenWidth-screenShape)*(screenHeight+distanceUnits)+numberis24Hour+numberisTouchScreen;
		var deviceID2 = numberis24Hour+numberisTouchScreen;
		var mtest = (numberisTouchScreen+distanceUnits)*screenWidth+(screenHeight-numberis24Hour)*screenShape;

		//! Training effect
		if (info.trainingEffect != null) {
            mtrainingEffect = info.trainingEffect;
        }		
			
        //! Calculate lap distance
        var mLapElapsedDistance = 0.0;
        if (info.elapsedDistance != null) {
            mLapElapsedDistance = info.elapsedDistance - mLastLapDistMarker;
        }

        //! Calculate lap time and convert timers from milliseconds to seconds
        var mTimerTime      = 0;
        var mLapTimerTime   = 0;

        if (info.timerTime != null) {
            mTimerTime = info.timerTime / 1000;
            mLapTimerTime = (info.timerTime - mLastLapTimeMarker) / 1000;
        }

        //! Calculate lap speeds
        var mLapSpeed = 0.0;
        var mLastLapSpeed = 0.0;
        if (mLapTimerTime > 0 && mLapElapsedDistance > 0) {
            mLapSpeed = mLapElapsedDistance / mLapTimerTime;
        }
        if (mLastLapTimerTime > 0 && mLastLapElapsedDistance > 0) {
            mLastLapSpeed = mLastLapElapsedDistance / mLastLapTimerTime;
        }

		//!Calculate power metrics
        var mPowerWarningunder = uRequiredPower.substring(0, 3);
        var mPowerWarningupper = uRequiredPower.substring(4, 7);
        mPowerWarningunder = mPowerWarningunder.toNumber();
        mPowerWarningupper = mPowerWarningupper.toNumber(); 

		//! Alert when out of predefined powerzone
		var vibrateData = [
			new Attention.VibeProfile( 100, 100 )
		];
		var DisplayPower  = (info.currentPower != null) ? info.currentPower : 0;
		if (DisplayPower>mPowerWarningupper or DisplayPower<mPowerWarningunder) {
			 //!Toybox.Attention.playTone(TONE_LOUD_BEEP);		 
			 if (Toybox.Attention has :vibrate && uNoAlerts == false) {
			 	vibrateseconds = vibrateseconds + 1;	 		  			
    			if (vibrateseconds == uWarningFreq) {
    				if (DisplayPower>mPowerWarningupper) {
    					Toybox.Attention.vibrate(vibrateData);
    					if (uAlertbeep == true) {
    						Attention.playTone(Attention.TONE_LOW_BATTERY);
    					}
    				} else {
    					if (uAlertbeep == true) {
    						Attention.playTone(Attention.TONE_LOUD_BEEP);
    					}
    				Toybox.Attention.vibrate(vibrateData);
    				}
    				vibrateseconds = 0;
    			}	
			 }
			 
		}	
		

        //! Calculate ETA
        if (info.elapsedDistance != null && info.timerTime != null) {
            if (uETAfromLap == true ) {
            	if (mLastLapTimerTime > 0 && mLastLapElapsedDistance > 0 && mLaps > 1) {
            		if (uRacedistance > info.elapsedDistance) {
            			mETA = info.timerTime/1000 + (uRacedistance - info.elapsedDistance)/ mLastLapSpeed;
            		} else {
            			mETA = 0;
            		}
            	}
            } else {
            	if (info.elapsedDistance > 5) {
            		mETA = uRacedistance / (1000*info.elapsedDistance/info.timerTime);
            	}
            }
        }

		//! Determine required finish time and calculate required pace 	
        var mRacehour = uRacetime.substring(0, 2);
        var mRacemin = uRacetime.substring(3, 5);
        var mRacesec = uRacetime.substring(6, 8);
        mRacehour = mRacehour.toNumber();
        mRacemin = mRacemin.toNumber();
        mRacesec = mRacesec.toNumber();
        var mRacetime = mRacehour*3600 + mRacemin*60 + mRacesec;

        
        if (uShowDemo == false) {
        	if (umyNumber != mtest && mTimerTime > 900)  {
        		uShowDemo = true;        		
        	}
        }

        

     if (uShowDemo == false ) {
        //!
        //! Draw colour indicators
        //!
		
        //! HR zone
        mColour = Graphics.COLOR_LT_GRAY; //! No zone default light grey
        var mCurrentHeartRate = "--";
        var  mCurrentHeartZone = 1;
        if (info.currentHeartRate != null) {
            mCurrentHeartRate = info.currentHeartRate;
            if (uHrZones != null) {
                if (mCurrentHeartRate >= uHrZones[4]) {
                    mColour = Graphics.COLOR_RED;        //! Maximum (Z5)
                    mCurrentHeartZone = 5;
                } else if (mCurrentHeartRate >= uHrZones[3]) {
                    mColour = Graphics.COLOR_ORANGE;    //! Threshold (Z4)
                    mCurrentHeartZone = 4;
                } else if (mCurrentHeartRate >= uHrZones[2]) {
                    mColour = Graphics.COLOR_GREEN;        //! Aerobic (Z3)
                    mCurrentHeartZone = 3;
                } else if (mCurrentHeartRate >= uHrZones[1]) {
                    mColour = Graphics.COLOR_BLUE;        //! Easy (Z2)
                    mCurrentHeartZone = 2;
                } //! Else Warm-up (Z1) and no zone both inherit default light grey here
            }
        }
        if (uHeartratefield != 2 ) {
        	dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(0, 101, 78, 21);
        }

        //! Cadence zone (fixed thresholds and colours to match Garmin Connect)
        var mColourCadence = Graphics.COLOR_LT_GRAY;
        if (info.currentCadence != null) {
            if (info.currentCadence > 183) {
                mColourCadence = Graphics.COLOR_PURPLE;
            } else if (info.currentCadence >= 174) {
                mColourCadence = Graphics.COLOR_BLUE;
            } else if (info.currentCadence >= 164) {
                mColourCadence = Graphics.COLOR_GREEN;
            } else if (info.currentCadence >= 153) {
                mColourCadence = Graphics.COLOR_ORANGE;
            } else if (info.currentCadence >= 120) {
                mColourCadence = Graphics.COLOR_RED;
            } //! Else no cadence or walking/stopped inherits default light grey here
        }
        if (uMiddlerightMetric == 13) {
        	dc.setColor(mColourCadence, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(179, 101, 83, 21);
		}
		
		//! Draw separator lines
        dc.setColor(mColourLine, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        //! Horizontal thirds
        dc.drawLine(0,   100,  257, 100);
        dc.drawLine(0,   169, 257, 169);

        //! Top vertical divider
        dc.drawLine(129, 31,  129, 100);

        //! Centre vertical dividers
        if (uHeartratefield != 2 ) {
            dc.drawLine(79,  100,  79,  169);
        }
        dc.drawLine(178, 100,  178, 169);

        //! Bottom vertical divider
        dc.drawLine(129, 169, 129, 242);
        
        //! Bottom horizontal divider
        dc.drawLine(57, 242, 199, 242);

        //! Top centre mini-field separator
        dc.drawRoundedRectangle(86, -12, 86, 43, 4);

        //!
        //! Draw field values
        //! =================
        //!



		dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);
		
		//! Show number of laps or clock with current time in top
		if (uShowlaps == true) {
			 dc.drawText(114, -4, Graphics.FONT_MEDIUM, mLaps, Graphics.TEXT_JUSTIFY_CENTER);
			 dc.drawText(152, 0, Graphics.FONT_XTINY, "lap", Graphics.TEXT_JUSTIFY_CENTER);
		} else {
			var myTime = Toybox.System.getClockTime(); 
	    	var strTime = myTime.hour.format("%02d") + ":" + myTime.min.format("%02d");
			dc.drawText(128, -4, Graphics.FONT_MEDIUM, strTime, Graphics.TEXT_JUSTIFY_CENTER);
		}
		
        //! Top row left: time
        var mTime = mTimerTime;
        var lTime = "Timer";
        if (uTimerDisplay == 1) {
            mTime = mLapTimerTime;
            lTime = "LapTime";
        } else if (uTimerDisplay == 2) {
            mTime = mLastLapTimerTime;
            lTime = "Last Lap";
        } else if (uTimerDisplay == 3) {
            mTime = mTimerTime / mLaps;
            lTime = "Avg LapT";
        }

        var fTimerSecs = (mTime % 60).format("%02d");
        var fTimer = (mTime / 60).format("%d") + ":" + fTimerSecs;  //! Format time as m:ss
        var x = 77;
        if (mTime > 3599) {
            //! (Re-)format time as h:mm(ss) if more than an hour
            fTimer = (mTime / 3600).format("%d") + ":" + (mTime / 60 % 60).format("%02d");
            x = 62;
            dc.drawText(102, 66, Graphics.FONT_TINY, fTimerSecs, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.drawText(x, 75, Graphics.FONT_NUMBER_MILD, fTimer, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(81, 41, Graphics.FONT_XTINY,  lTime, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

        //! Top row right: distance
        var mDistance = (info.elapsedDistance != null) ? info.elapsedDistance / unitD : 0;
        var lDistance = "Distance";
        if (uDistDisplay == 1) {
            mDistance = mLapElapsedDistance / unitD;
            lDistance = "Lap Dist.";
        } else if (uDistDisplay == 2) {
            mDistance = mLastLapElapsedDistance / unitD;
            lDistance = "L-1 Dist.";
        }

        var fString = "%.2f";
         if (mDistance > 100) {
             fString = "%.1f";
         }
        dc.drawText(184, 75, Graphics.FONT_NUMBER_MILD, mDistance.format(fString), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(179, 41, Graphics.FONT_XTINY,  lDistance, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

        //! Centre middle: current pace
        var Averagespeedinmpersec 			= 0;
        var fCurrentPace 					= 0;
        var currentSpeedtest				= 0;
        if (info.currentSpeed != null) {
        	currentSpeedtest = info.currentSpeed; 
        }
        if (currentSpeedtest > 0) {
            if (uAveragedPace == true) {
            	//! Calculate average pace
				if (info.currentSpeed != null) {
        		Pace5 								= Pace4;
        		Pace4 								= Pace3;
        		Pace3 								= Pace2;
        		Pace2 								= Pace1;
        		Pace1								= info.currentSpeed; 
        		} else {
					Pace5 								= Pace4;
    	    		Pace4 								= Pace3;
        			Pace3 								= Pace2;
        			Pace2 								= Pace1;
        			Pace1								= 0;
				}
				Averagespeedinmpersec= (Pace1+Pace2+Pace3+Pace4+Pace5)/5;
				if (uRoundedPace) {
                	fCurrentPace 					= unitP/(Math.round( (unitP/Averagespeedinmpersec) / 5 ) * 5);
                } else {
                	fCurrentPace 					= Averagespeedinmpersec;
                }
			} else {
				if (uRoundedPace) {
                	fCurrentPace = unitP/(Math.round( (unitP/info.currentSpeed) / 5 ) * 5);
                } else {
                	fCurrentPace = info.currentSpeed;
                }
            }

			if ( uPacefield == 0 ) {
            	if (uHeartratefield != 2 ) {
            		dc.drawText(127, 147, Graphics.FONT_NUMBER_MILD, fmtPace(fCurrentPace), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            	} else {
            		dc.drawText(104, 135, Graphics.FONT_NUMBER_MEDIUM, fmtPace(fCurrentPace), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            	}
            } else if (uPacefield == 1) {
            	var fCurrentPace = 100/info.currentSpeed;
            	fString = "%.1f";
            	if (uHeartratefield != 2 ) {
            		dc.drawText(127, 147, Graphics.FONT_NUMBER_MILD, fCurrentPace.format(fString), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            	} else {
            		dc.drawText(104, 135, Graphics.FONT_NUMBER_MEDIUM, fCurrentPace.format(fString), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            	}
            } else {
            	var fCurrentPace = 3.6*info.currentSpeed*1000/unitP;
            	fString = "%.1f";
            	if (uHeartratefield != 2 ) {
            		dc.drawText(127, 147, Graphics.FONT_NUMBER_MILD, fCurrentPace.format(fString), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            	} else {
            		dc.drawText(104, 135, Graphics.FONT_NUMBER_HOT, fCurrentPace.format(fString), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            	}

            }
        }
        
        if ( uColoringPaceFromAver == true ) {
        	if (info.averageSpeed != null and info.averageSpeed > 0.1) {
        		uTargetPaceMetric = unitD/info.averageSpeed;
        	}
        } else {
        		uTargetPaceMetric = unitD*mRacetime/uRacedistance;
        }

        //! Current pace vs target pace colour indicator
        if ( uTargetPaceMetric > 2 ) {
        	mColour = Graphics.COLOR_LT_GRAY;
        	if (info.currentSpeed != null) { 
       	     var uTargetSpeed = unitP/uTargetPaceMetric;
        	    if (uTargetSpeed > 0) {
            	    var paceDeviation = (fCurrentPace / uTargetSpeed);
            	    if (uMaxColoringPace == true ) {
                		if (paceDeviation < 0.95) {    //! More than 5% slower
                			if (paceDeviation < 0.90) {    //! More than 10% slower
                				mColour = Graphics.COLOR_RED;
       		         		} else {
            	        		mColour = Graphics.COLOR_ORANGE;
                	    	}
              	  		} else if (paceDeviation <= 1.05) {    //! Within +/-5% of target pace
                	    	mColour = Graphics.COLOR_GREEN;
              	  		} else {  
                			if (paceDeviation > 1.10) {   //! More than 10% faster
                				mColour = Graphics.COLOR_PURPLE;
            	    		} else {
                	    		mColour = Graphics.COLOR_BLUE;
                	    	}
            	    	}
            	    } else {
            	    	if (paceDeviation < 0.95) {    //! More than 5% slower
            	    		mColour = Graphics.COLOR_RED;
            	    	} else if (paceDeviation > 1.05) {
            	    		mColour = Graphics.COLOR_PURPLE;
            	    	} else { 
            	    		mColour = Graphics.COLOR_GREEN;
            	    	}
            	    }
          	  }
        	}    
        } else {
        mColour = mColourFont;
        }
        
        dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        if (uHeartratefield != 2 ) {
        	dc.fillRectangle(80, 101, 97, 21);
        	if ( uTargetPaceMetric > 2 ) {
            	mColour = mColourFont;
        	} else {
        		mColour = mColourBackGround;
        	}
        	dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        	if ( uPacefield == 2 ) {
        		dc.drawText(128, 109, Graphics.FONT_XTINY,  "Speed", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        	} else {	
        		dc.drawText(128, 109, Graphics.FONT_XTINY,  "Pace", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        	}
		} else {
			if ( uTargetPaceMetric > 2 ) {
            	mColour = mColourFont;
        	} else {
        		mColour = mColourBackGround;
        	}
			dc.fillRectangle(0, 101, 34, 67);
            dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
            if ( uPacefield == 2 ) {
            	dc.drawText(16, 113, Graphics.FONT_XTINY,  "S", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        		dc.drawText(16, 144, Graphics.FONT_XTINY,  "p", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        		dc.drawText(16, 154, Graphics.FONT_XTINY,  "d", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
        		dc.drawText(16, 111, Graphics.FONT_XTINY,  "P", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        		dc.drawText(16, 126, Graphics.FONT_XTINY,  "a", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        		dc.drawText(16, 141, Graphics.FONT_XTINY,  "c", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        		dc.drawText(16, 156, Graphics.FONT_XTINY,  "e", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        	}
		}
		
		mColour = mColourFont;
		dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        //! Centre left: heart rate 
        if (uHeartratefield != 2 ) {
        	if (uHeartratefield == 0) {
            	dc.drawText(37, 147, Graphics.FONT_NUMBER_MILD, mCurrentHeartRate, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        		dc.drawText(39, 109, Graphics.FONT_XTINY, "HR", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
            	dc.drawText(37, 147, Graphics.FONT_NUMBER_MILD, mCurrentHeartZone, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        		dc.drawText(39, 109, Graphics.FONT_XTINY, "HR zone", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            }
            		
		}

		
        //! Centre right: cadence
        var fieldValue     = 0.0;
        var fieldLabel     = "A Pace";
        var isPace         = true;
        if (uMiddlerightMetric == 0 && info.averageSpeed != null) {
            fieldValue = info.averageSpeed;
            //fieldLabel = "A Pace";
        } else if (uMiddlerightMetric == 1) {
            fieldValue = mLapSpeed;
            fieldLabel = "L Pace";
        } else if (uMiddlerightMetric == 2) {
            fieldValue = mLastLapSpeed;
            fieldLabel = "L-1Pace";
        }  else if (uMiddlerightMetric == 3) {
           	fieldValue = (info.altitude != null) ? info.altitude : 0;
		  	fieldValue = (unitD == 1609.344) ? fieldValue*3.2808 : fieldValue;
           	fieldValue = Math.round(fieldValue).toNumber();
            fieldLabel = "Altitude";
        }  else if (uMiddlerightMetric == 4) {
           	fieldValue = (info.totalAscent != null) ? info.totalAscent : 0;
           	fieldValue = (unitD == 1609.344) ? fieldValue*3.2808 : fieldValue;
           	fieldValue = Math.round(fieldValue).toNumber();
            fieldLabel = "EL gain";
        }  else if (uMiddlerightMetric == 5) {
           	fieldValue = (info.totalDescent != null) ? info.totalDescent : 0;
           	fieldValue = (unitD == 1609.344) ? fieldValue*3.2808 : fieldValue;
           	fieldValue = Math.round(fieldValue).toNumber();
            fieldLabel = "EL loss";
        } else if (uMiddlerightMetric == 6) {
           	fieldValue = 0;
            fieldLabel = "Error";
        } else if (uMiddlerightMetric == 8) {
        	fieldLabel = "Rq pace ";
        	if (info.elapsedDistance != null and info.timerTime != null and mRacetime != info.timerTime/1000 and mRacetime > info.timerTime/1000) {
        			fieldValue = (uRacedistance - info.elapsedDistance) / (mRacetime - info.timerTime/1000); 
        	}
        }  else if (uMiddlerightMetric == 9) {
           	fieldValue = mCurrentHeartRate;
            fieldLabel = "HR rate";
        }  else if (uMiddlerightMetric == 10) {
           	fieldValue = mCurrentHeartZone;
            fieldLabel = "HR zone";
        }  else if (uMiddlerightMetric == 11) {
           	fieldValue = SPower;
            fieldLabel = "Power";
        }  else if (uMiddlerightMetric == 12) {
           	fieldValue = mtrainingEffect;
            fieldLabel = "T effect";
        }  else if (uMiddlerightMetric == 13) {
           	fieldValue = (info.currentCadence != null) ? info.currentCadence : 0;
            fieldLabel = "Cadence";
        }
             
        if (uMiddlerightMetric == 6 or uMiddlerightMetric == 7 or uMiddlerightMetric == 8) {
          	if (mETA < mRacetime) {
        		mColour = Graphics.COLOR_GREEN;
        	} else {
        		mColour = Graphics.COLOR_RED;
        	}
        	dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(179, 101, 83, 21);
        	mColour = mColourFont1;	
        	dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        }	
        	
        if ( uMiddlerightMetric == 7 ) {
        	dc.drawText(215, 147, Graphics.FONT_NUMBER_MILD, EstimatedTimeSmall(fieldValue) , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
       	} else if (uMiddlerightMetric == 6) {    
			dc.drawText(218, 147, Graphics.FONT_NUMBER_MILD, fieldValue , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (uMiddlerightMetric == 0 or uMiddlerightMetric == 1 or uMiddlerightMetric == 2 or uMiddlerightMetric == 8 ) {
        	if (fieldValue > 0) {
            	dc.drawText(218, 147, Graphics.FONT_NUMBER_MILD, (isPace) ? fmtPace(fieldValue) : fieldValue, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else if ( uMiddlerightMetric == 3 or uMiddlerightMetric == 4 or uMiddlerightMetric == 5 or uMiddlerightMetric == 9 or uMiddlerightMetric == 10 or uMiddlerightMetric == 11 or uMiddlerightMetric == 13 ) {
        	dc.drawText(215, 147, Graphics.FONT_NUMBER_MILD, (info.altitude != null) ? fieldValue : 0, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( uMiddlerightMetric == 12 ) {
        	dc.drawText(201, 147, Graphics.FONT_NUMBER_MILD, fieldValue.format("%.2f"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }      
        dc.drawText(218, 109, Graphics.FONT_XTINY, fieldLabel, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
      
        //! Bottom left
        fieldValue     = 0.0;
        fieldLabel     = "A Pace";
        isPace         = true;
        if (uBottomLeftMetric == 0 && info.averageSpeed != null) {
            fieldValue = info.averageSpeed;
            //fieldLabel = "A Pace";
        } else if (uBottomLeftMetric == 1) {
            fieldValue = mLapSpeed;
            fieldLabel = "L Pace";
        } else if (uBottomLeftMetric == 2) {
            fieldValue = mLastLapSpeed;
            fieldLabel = "L-1Pace";
        }  else if (uBottomLeftMetric == 3) {
           	fieldValue = (info.altitude != null) ? info.altitude : 0;
		  	fieldValue = (unitD == 1609.344) ? fieldValue*3.2808 : fieldValue;
           	fieldValue = Math.round(fieldValue).toNumber();
           	fieldLabel = "Altitude";
        }  else if (uBottomLeftMetric == 4) {
           	fieldValue = (info.totalAscent != null) ? info.totalAscent : 0;
           	fieldValue = (unitD == 1609.344) ? fieldValue*3.2808 : fieldValue;
           	fieldValue = Math.round(fieldValue).toNumber();
            fieldLabel = "EL gain";
        }  else if (uBottomLeftMetric == 5) {
           	fieldValue = (info.totalDescent != null) ? info.totalDescent : 0;
           	fieldValue = (unitD == 1609.344) ? fieldValue*3.2808 : fieldValue;
           	fieldValue = Math.round(fieldValue).toNumber();
            fieldLabel = "EL loss";
        } else if (uBottomLeftMetric == 6) {
           	fieldValue = mETA*1000;
            fieldLabel = "ETA";
        } else if (uBottomLeftMetric == 7) {
        	fieldLabel = "Deviation ";
        	if ( mLaps == 1 ) {
        		fieldValue = 0;
        	} else {
        		fieldValue = 1000*Math.round(mRacetime - mETA).toNumber() ;
        	}
        	if (fieldValue < 0) {
        		fieldValue = - fieldValue;
        	}
        } else if (uBottomLeftMetric == 8) {
        	fieldLabel = "Req pace ";
        	if (info.elapsedDistance != null and info.timerTime != null and mRacetime != info.timerTime/1000 and mRacetime > info.timerTime/1000) {
        			fieldValue = (uRacedistance - info.elapsedDistance) / (mRacetime - info.timerTime/1000); 
        	}
        }  else if (uBottomLeftMetric == 9) {
           	fieldValue = mCurrentHeartRate;
            fieldLabel = "HR rate";
        }  else if (uBottomLeftMetric == 10) {
           	fieldValue = mCurrentHeartZone;
            fieldLabel = "HR zone";
        }  else if (uBottomLeftMetric == 11) {
           	fieldValue = SPower;
            fieldLabel = "Power";
        }  else if (uBottomLeftMetric == 12) {
           	fieldValue = mtrainingEffect;
            fieldLabel = "T effect";
        }
        
        if (uBottomLeftMetric == 6 or uBottomLeftMetric == 7 or uBottomLeftMetric == 8) {
          	if (mETA < mRacetime) {
        		mColour = Graphics.COLOR_GREEN;
        	} else {
        		mColour = Graphics.COLOR_RED;
        	}
        	dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(20, 218, 108, 23);
        	mColour = mColourFont1;	
        	dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        }	
        	
        if ( uBottomLeftMetric == 7 ) {
        	dc.drawText(75, 195, Graphics.FONT_NUMBER_MILD, EstimatedTimeSmall(fieldValue) , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
       	} else if (uBottomLeftMetric == 6) {    
			dc.drawText(74, 195, Graphics.FONT_MEDIUM, EstimatedTime(fieldValue) , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (uBottomLeftMetric == 0 or uBottomLeftMetric == 1 or uBottomLeftMetric == 2 or uBottomLeftMetric == 8 ) {
        	if (fieldValue > 0) {
            	dc.drawText(75, 195, Graphics.FONT_NUMBER_MILD, (isPace) ? fmtPace(fieldValue) : fieldValue, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else if ( uBottomLeftMetric == 3 or uBottomLeftMetric == 4 or uBottomLeftMetric == 5 or uBottomLeftMetric == 9 or uBottomLeftMetric == 10 or uBottomLeftMetric == 11 ) {
        	dc.drawText(75, 195, Graphics.FONT_NUMBER_MILD, (info.altitude != null) ? fieldValue : 0, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( uBottomLeftMetric == 12 ) {
        	dc.drawText(75, 195, Graphics.FONT_NUMBER_MILD, fieldValue.format("%.2f"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }      
        dc.drawText(87, 226, Graphics.FONT_XTINY, fieldLabel, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

        //! Bottom right
        fieldValue     = 0.0;
        fieldLabel     = "A Pace";
        isPace         = true;
        if (uBottomRightMetric == 0 && info.averageSpeed != null) {
            fieldValue = info.averageSpeed;
            //fieldLabel = "A Pace";
        } else if (uBottomRightMetric == 1) {
            fieldValue = mLapSpeed;
            fieldLabel = "L Pace";
        } else if (uBottomRightMetric == 2) {
            fieldValue = mLastLapSpeed;
            fieldLabel = "L-1Pace";
        }  else if (uBottomRightMetric == 3) {
           	fieldValue = (info.altitude != null) ? info.altitude : 0;
		  	fieldValue = (unitD == 1609.344) ? fieldValue*3.2808 : fieldValue;
           	fieldValue = Math.round(fieldValue).toNumber();
           	fieldLabel = "Altitude";
        }  else if (uBottomRightMetric == 4) {
           	fieldValue = (info.totalAscent != null) ? info.totalAscent : 0;
           	fieldValue = (unitD == 1609.344) ? fieldValue*3.2808 : fieldValue;
           	fieldValue = Math.round(fieldValue).toNumber();
            fieldLabel = "EL gain";
        }  else if (uBottomRightMetric == 5) {
           	fieldValue = (info.totalDescent != null) ? info.totalDescent : 0;
           	fieldValue = (unitD == 1609.344) ? fieldValue*3.2808 : fieldValue;
           	fieldValue = Math.round(fieldValue).toNumber();
            fieldLabel = "EL loss";
        } else if (uBottomRightMetric == 6) {
           	fieldValue = mETA*1000;
            fieldLabel = "ETA";
        } else if (uBottomRightMetric == 7) {
         	fieldLabel = "  Deviation ";
        	if ( mLaps == 1 ) {
        		fieldValue = 0;
        	} else {
        		fieldValue = 1000*Math.round(mRacetime - mETA).toNumber() ;
        	}
        	if (fieldValue < 0) {
        		fieldValue = - fieldValue;
        	}
        } else if (uBottomRightMetric == 8) {
        	fieldLabel = "  Req pace";
        	if (info.elapsedDistance != null and info.timerTime != null and mRacetime != info.timerTime/1000 and mRacetime > info.timerTime/1000) {
        			fieldValue = (uRacedistance - info.elapsedDistance) / (mRacetime - info.timerTime/1000); 
        	}
        }  else if (uBottomRightMetric == 9) {
           	fieldValue = mCurrentHeartRate;
            fieldLabel = "HR rate";
        }  else if (uBottomRightMetric == 10) {
           	fieldValue = mCurrentHeartZone;
            fieldLabel = "HR zone";
        }  else if (uBottomRightMetric == 11) {
           	fieldValue = SPower;
            fieldLabel = "Power";
        }  else if (uBottomRightMetric == 12) {
           	fieldValue = mtrainingEffect;
            fieldLabel = "T effect";
        }
      
        if (uBottomRightMetric == 6 or uBottomRightMetric == 7 or uBottomRightMetric == 8) {
          	if (mETA < mRacetime) {
        		mColour = Graphics.COLOR_GREEN;
        	} else {
        		mColour = Graphics.COLOR_RED;
        	}
        	dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(130, 218, 108, 23);
        	mColour = mColourFont1;	
        	dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        }	
        	
        if ( uBottomRightMetric == 7 ) {
        	dc.drawText(181, 195, Graphics.FONT_NUMBER_MILD, EstimatedTimeSmall(fieldValue) , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
       	} else if (uBottomRightMetric == 6) {    
   			dc.drawText(184, 195, Graphics.FONT_MEDIUM, EstimatedTime(fieldValue) , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (uBottomRightMetric == 0 or uBottomRightMetric == 1 or uBottomRightMetric == 2 or uBottomRightMetric == 8 ) {
        	if (fieldValue > 0) {
            	dc.drawText(179, 195, Graphics.FONT_NUMBER_MILD, (isPace) ? fmtPace(fieldValue) : fieldValue, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else if ( uBottomRightMetric == 3 or uBottomRightMetric == 4 or uBottomRightMetric == 5 or uBottomRightMetric == 9 or uBottomRightMetric == 10 or uBottomRightMetric == 11) {
        	dc.drawText(165, 195, Graphics.FONT_NUMBER_MILD, (info.altitude != null) ? fieldValue : 0, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else if ( uBottomRightMetric == 12 ) {
        	dc.drawText(179, 195, Graphics.FONT_NUMBER_MILD, fieldValue.format("%.2f"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.drawText(169, 226, Graphics.FONT_XTINY, fieldLabel, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        
        
		//! Bottom battery indicator
		var stats = Sys.getSystemStats();
		var pwr = stats.battery;
		dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);
		dc.fillRectangle(100, 244, 59, 14);
		dc.fillRectangle(158, 247, 3, 7);
		
		dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);
		dc.fillRectangle(102, 246, 54, 10);
		
		dc.setColor(mColourBackGround, Graphics.COLOR_TRANSPARENT);
		var Startstatuspwrbr = 102 + pwr*0.54  ;
		var Endstatuspwrbr = 54 - pwr*0.54 ;
		dc.fillRectangle(Startstatuspwrbr, 246, Endstatuspwrbr, 10);		
        
      } else {
		dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);

		if (umyNumber == mtest) {
			dc.drawText(118, 120, Graphics.FONT_XTINY, "Registered !!", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(81, 160, Graphics.FONT_XTINY, "License code: ", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(180, 160, Graphics.FONT_XTINY, mtest, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		} else {
      		dc.drawText(118, 30, Graphics.FONT_XTINY, "License needed !!", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
      		dc.drawText(118, 60, Graphics.FONT_XTINY, "Run is recorded though", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(60, 122, Graphics.FONT_XTINY, "ID 1: ", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(161, 115, Graphics.FONT_NUMBER_MILD, deviceID1, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(60, 177, Graphics.FONT_XTINY, "ID 2: " , Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			dc.drawText(161, 170, Graphics.FONT_NUMBER_MILD, deviceID2, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
      	}

      	
		
      }
    }

    function EstimatedTime(secs) {
        var s = (secs).toLong();
        return (s / 3600000).format("%0d") + ":" + (s /60000 % 60).format("%02d") + ":" + (s /1000 % 60).format("%02d");
    }

    function EstimatedTimeSmall(secs) {
        var s = (secs).toLong();
        return (s /60000 % 60).format("%02d") + ":" + (s /1000 % 60).format("%02d");
    }

    function fmtPace(secs) {
        var s = (unitP/secs).toLong();
        return (s / 60).format("%0d") + ":" + (s % 60).format("%02d");
    }

	function Lapaction () {
        var info = Activity.getActivityInfo();
        mLastLapTimerTime        = (info.timerTime - mLastLapTimeMarker) / 1000;
        mLastLapElapsedDistance  = (info.elapsedDistance != null) ? info.elapsedDistance - mLastLapDistMarker : 0;
        mLaps++;
        mLastLapDistMarker           = info.elapsedDistance;
        mLastLapTimeMarker           = info.timerTime;
        mLastLapStoppedTimeMarker    = mStoppedTime;
        mLastLapStoppedDistMarker    = mStoppedDistance;
	}
}
