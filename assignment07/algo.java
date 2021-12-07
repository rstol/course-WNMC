package layer2_802Algorithms;

import plot.JEMultiPlotter;

import layer1_802Phy.JE802PhyMode;
import layer2_80211Mac.JE802_11BackoffEntity;
import layer2_80211Mac.JE802_11Mac;
import layer2_80211Mac.JE802_11MacAlgorithm;

public class algo extends JE802_11MacAlgorithm {
	
	private JE802_11BackoffEntity theBackoffEntityAC01;
	
	private double theSamplingTime_sec;
	private boolean flag_undefined = false;
	
	// PID controller params
	private double iTerm = 0; // integral state
	private double prevError = 0; // Last position error
	private double max = 100, min = 0; // Maximum and minimum allowable control value
	private double iGain = 0.01, // integral gain
			pGain = 1.0, // proportional gain
			dGain = 10.0; // derivative gain
	
	public algo(String name, JE802_11Mac mac) {
		super(name, mac);
		this.theBackoffEntityAC01 = this.mac.getBackoffEntity(1);
		message("I am station " + this.dot11MACAddress.toString() + ". My algorithm is called '" + this.algorithmName
				+ "'.", 10);
	}
	
	@Override
	public void compute() {
		this.theSamplingTime_sec =  this.mac.getMlme().getTheIterationPeriod().getTimeS(); // this sampling time can only be read after the MLME was constructed.
		
		// observe outcome:
		Integer currentQueueSize = this.theBackoffEntityAC01.getCurrentQueueSize();		
		Integer AIFSN = theBackoffEntityAC01.getDot11EDCAAIFSN();
		Integer CWmin = theBackoffEntityAC01.getDot11EDCACWmin();
		String phyMode = this.mac.getPhy().getCurrentPhyMode().toString();

		message("with the following parameters ...", 10);
		message("    AIFSN[AC01] = " + AIFSN.toString(), 10);
		message("    CWmin[AC01] = " + CWmin.toString(), 10);
		message("	 Phy mode    = " + phyMode, 10);
		message("... the backoff entity queues perform like this:", 10);
		message("    Currently used MAC queue slots: " + currentQueueSize, 10);

		double error = 0.0;
		PID_controller(error);

		// infer decision: (note, we just change the values arbitrarily
		if (flag_undefined) { // we should increase AIFSN
			AIFSN = AIFSN + 1;
		} else { // we should decrease AIFSN
			AIFSN = AIFSN - 1;
		}
		if (AIFSN >= 20)
			flag_undefined = false;
		if (AIFSN <= 2)
			flag_undefined = true;

		// act:
		theBackoffEntityAC01.setDot11EDCAAIFSN(AIFSN);
		theBackoffEntityAC01.setDot11EDCACWmin(CWmin);


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
