package layer2_802Algorithms;

import plot.JEMultiPlotter;
import statistics.JERandomVar;
import layer1_802Phy.JE802PhyMode;
import layer2_80211Mac.JE802_11BackoffEntity;
import layer2_80211Mac.JE802_11Mac;
import layer2_80211Mac.JE802_11MacAlgorithm;

public class EMACW extends JE802_11MacAlgorithm {
	
	private JE802_11BackoffEntity theBackoffEntity; // entity of AC: 1
	
	private double theSamplingTime_sec;
	private boolean cooperative_mode = true; // false = aggressiv TODO: use this
	
	private double ACP = 0.0; // Active Collisions Param: start cooperative by default
	private int prevCollisions = 0;
	private int prevTransmAttempts = 0;
	private JERandomVar randomVar; // uniform random variable in interval [0,1]
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

	
	public EMACW(String name, JE802_11Mac mac) {
		super(name, mac);
		this.theBackoffEntity = this.mac.getBackoffEntity(1);
		this.randomVar = new JERandomVar(this.theUniqueRandomGenerator, "Uniform", 0.0, 1.0);
		this.alpha = this.randomVar.nextvalue();
		this.CWmax = theBackoffEntity.getDot11EDCACWmax();
		this.CWmin = theBackoffEntity.getDot11EDCACWmin();
		
		message("I am station " + this.dot11MACAddress.toString() + ". My algorithm is called '" + this.algorithmName
				+ "'.", 10);
	}
	
	@Override
	public void compute() {
		this.theSamplingTime_sec =  this.mac.getMlme().getTheIterationPeriod().getTimeS(); // this sampling time can only be read after the MLME was constructed.
		
		// observe outcome:
		int totalTransmAttempts = (int) this.theBackoffEntity.getTheTxCnt();
		int totalCollisions = this.theBackoffEntity.getTheCollisionCnt(); // gets increased for unacked data and not receiving CTS for a RTS	
		Integer AIFSN = theBackoffEntity.getDot11EDCAAIFSN();
		
		int currCollisions = totalCollisions - prevCollisions;
		int currTransmAttempts = totalTransmAttempts - prevTransmAttempts;

		// exponential weighted moving average method
		// For every transmission, ACP is estimated at the station. 
		// The estimated current packet collisions indicates
		// whether there is congestion in the system. 
		// The value of ACP is reaching 1, meaning that almost all transmission attempts result in collisions
		if (currTransmAttempts > 0)  // don't divide by zero
			ACP = Math.max(0.0, alpha * (1.0 * currCollisions/currTransmAttempts) + (1 - alpha) * ACP); 
		int CW = Math.max(CWmin, (int) Math.round(CWmax * ACP));
		
		//TODO: after aggressive mode: Set alpha to higher value than before to ensure that AQP is accurate again in short time

		//TODO: if ACP is above some threshold i.e. T1=0.8 for some number of iterations (=high contention), then choose random iteration count in some small
		// 	  interval during which we artificially lower the CW (aggressiv). We continue to measure ACP as before and if during the 
		//	  aggressive mode the ACP falls below some threshold i.e. T2=0.5 we stop the aggressive mode prematurely. 

		message("with the following parameters ...");
		message("    AIFSN[AC01] = " + AIFSN.toString());
		message("	 current CWmin = " + CW + " ,CWmax = " + CWmax);
		message("	 ACP = " + ACP + ", alpha = " + alpha);
		if (currTransmAttempts > 0) 
			message("	ratio = " + 1.0 * currCollisions/currTransmAttempts);
		message("... the algorithm performs like this:");
		message("--- Discarded packets: " + this.theBackoffEntity.getTheDiscardCnt());
		message("    Num of packet transmission attempts: " + this.theBackoffEntity.getTheTxCnt());
		message("    Num of received acknowledgments: " + this.theBackoffEntity.getTheAckCnt());
		message("    Estimated num of collisions: " + this.theBackoffEntity.getTheCollisionCnt());
		message("    Estimated num of current collisions: " + currCollisions);
		message("    Num of current transmission attempts: " + currTransmAttempts);

		double error = 0.0;
		PID_controller(error);

		// act:
		theBackoffEntity.setDot11EDCACWmin(CW);

		//set power to constant 0 dBm
		if (this.mac.getPhy().getCurrentTransmitPower_dBm() != 0.0)
			this.mac.getPhy().setCurrentTransmitPower_dBm(0.0);
		//set phy mode to constant highest throughput
		if (!this.mac.getPhy().getCurrentPhyMode().toString().equals("64QAM34"))
			this.mac.getPhy().setCurrentPhyMode("64QAM34");
		// update variables
		prevCollisions += currCollisions;
		prevTransmAttempts += currTransmAttempts;
	}
	
	@Override
	public void plot() {
		// TODO
		// if (plotter == null) {
		// 	plotter = new JEMultiPlotter("PID Controller, Station " + this.dot11MACAddress.toString(), "current", "time [s]", "MAC Queue", this.theUniqueEventScheduler.getEmulationEnd().getTimeMs() / 1000.0, true);
		// 	plotter.display();
		// }
		// 	plotter.plot(((Double) theUniqueEventScheduler.now().getTimeMs()).doubleValue() / 1000.0, theBackoffEntity.getCurrentQueueSize(), 0);
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
