package layer2_802Algorithms;

import plot.JEMultiPlotter;
import statistics.JERandomVar;
import layer1_802Phy.JE802PhyMode;
import layer2_80211Mac.JE802_11BackoffEntity;
import layer2_80211Mac.JE802_11Mac;
import layer2_80211Mac.JE802_11MacAlgorithm;

public class algo extends JE802_11MacAlgorithm {
	
	private JE802_11BackoffEntity theBackoffEntityAC01;
	
	private double theSamplingTime_sec;
	private boolean flag_undefined = false;
	private boolean cooperative_mode = false; // false = aggressiv TODO: use this
	
	private double AQP; // Active Queue Param
	private JERandomVar randomVar; // random variable with value in [0,1]
	private double alpha; // random values in [0,1], used for exponential weighted moving average
	private int CWmax = 1023; // maximal contention window
	private int CWmin = 31; // minimal contention window
	// PID controller params
	private double iTerm = 0; // integral state
	private double prevError = 0; // Last position error
	private double max = 100, min = 0; // Maximum and minimum allowable control value
	private double iGain = 0.01, // integral gain
			pGain = 1.0, // proportional gain
			dGain = 10.0; // derivative gain
	// timer params
	private int currentTimer = 0;
	private int currentTimerID = -1;
	
	public algo(String name, JE802_11Mac mac) {
		super(name, mac);
		this.theBackoffEntityAC01 = this.mac.getBackoffEntity(1);
		this.randomVar = new JERandomVar(this.theUniqueRandomGenerator, "Uniform", 0.0, 1.0);
		this.alpha = this.randomVar.nextvalue();
		this.AQP = 1.0 * (theBackoffEntityAC01.getQueueSize() - theBackoffEntityAC01.getCurrentQueueSize()) / theBackoffEntityAC01.getQueueSize();
		this.CWmax = theBackoffEntityAC01.getDot11EDCACWmax();
		this.CWmin = theBackoffEntityAC01.getDot11EDCACWmin();
		
		message("I am station " + this.dot11MACAddress.toString() + ". My algorithm is called '" + this.algorithmName
				+ "'.", 10);
	}
	
	@Override
	public void compute() {
		this.theSamplingTime_sec =  this.mac.getMlme().getTheIterationPeriod().getTimeS(); // this sampling time can only be read after the MLME was constructed.
		
		// observe outcome:
		int TQS = theBackoffEntityAC01.getQueueSize();
		int currentQueueSize = this.theBackoffEntityAC01.getCurrentQueueSize();		
		Integer AIFSN = theBackoffEntityAC01.getDot11EDCAAIFSN();
		String phyMode = this.mac.getPhy().getCurrentPhyMode().toString();

		double AQS = TQS - currentQueueSize; // available queue size
		// exponential weighted moving average method
		// For every transmission, AQP is estimated at the transmit-
		// ting node. The estimated current buffer availability indicates
		// whether queue reaches its full capacity soon or it has sufficient
		// room for more packets. The value of AQP is reaching 1, meaning that the queue becomes full
		AQP = alpha * (AQS/TQS) + (1 - alpha) * AQP;
		int CW = Math.max(CWmin, (int) Math.round(CWmax * AQP));
		
		// after aggressive mode: Set alpha to higher value than before to ensure that AQP is accurate again in short time

		message("with the following parameters ...", 10);
		message("    AIFSN[AC01] = " + AIFSN.toString(), 10);
		message("	 Phy mode    = " + phyMode, 10);
		message("... the backoff entity queues perform like this:", 10);
		message("    Currently used MAC queue slots: " + currentQueueSize, 10);

		double error = 0.0;
		PID_controller(error);

		// act:
		theBackoffEntityAC01.setDot11EDCAAIFSN(AIFSN);
		theBackoffEntityAC01.setDot11EDCACWmin(CW);

		//set power to constant 0 dBm
		if (this.mac.getPhy().getCurrentTransmitPower_dBm() != 0.0)
			this.mac.getPhy().setCurrentTransmitPower_dBm(0.0);
		//set phy mode to constant highest throughput
		if (!this.mac.getPhy().getCurrentPhyMode().toString().equals("64QAM34"))
			this.mac.getPhy().setCurrentPhyMode("64QAM34");
	}
	
	@Override
	public void plot() {
		if (plotter == null) {
			plotter = new JEMultiPlotter("PID Controller, Station " + this.dot11MACAddress.toString(), "current", "time [s]", "MAC Queue", this.theUniqueEventScheduler.getEmulationEnd().getTimeMs() / 1000.0, true);
			plotter.display();
		}
			plotter.plot(((Double) theUniqueEventScheduler.now().getTimeMs()).doubleValue() / 1000.0, theBackoffEntityAC01.getCurrentQueueSize(), 0);
	}

	private double PID_controller(double error) {
		// Compute integral
		iTerm += iGain * error;
		if (iTerm > max) iTerm = max;
		else if (iTerm < min) iTerm = min;
		// Compute PID output
		double out = pGain * error + iTerm - dGain * (error - prevError);
		// Apply limit to output value
		if (out > max) out = max;
		else if (out < min) out = min;

		prevError = error;
		return out;
	}
}
