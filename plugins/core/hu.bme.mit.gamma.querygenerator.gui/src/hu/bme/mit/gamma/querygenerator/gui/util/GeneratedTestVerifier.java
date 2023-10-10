/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.gui.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.AbstractMap;
import java.util.Map.Entry;
import java.util.logging.Level;
import java.util.logging.Logger;

import hu.bme.mit.gamma.dialog.DialogUtil;
import hu.bme.mit.gamma.querygenerator.application.View;
import hu.bme.mit.gamma.querygenerator.controller.AbstractController;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;

public class GeneratedTestVerifier implements Runnable {
	// Indicates whether the test generation process is cancelled
	private volatile boolean isCancelled = false;
	
	private final View view;
	
	protected final Logger logger = Logger.getLogger("GammaLogger");
	
	public GeneratedTestVerifier(View view, AbstractController controller) {
		this.view = view;
	}
	
	private AbstractController getController() {
		return view.getController();
	}
	
    /**
     * Verifies all generated queries (deadlock and reachability).
     */
	@Override
    public void run() {
    	final int SLEEP_INTERVAL = 250;
    	final int TIMEOUT = view.getTestGenerationTmeout() * (1000 / SLEEP_INTERVAL);
    	GuiVerifier verifier = null;
    	StringBuilder buffer = new StringBuilder();
    	// Disabling the verification buttons
		view.setVerificationButtons(false);
    	try (BufferedReader reader = new BufferedReader(new FileReader(new File(getController().getGeneratedQueryFile())))) {
    		Entry<String, String> query;
    		while ((query = readLineSkipComments(reader)) != null && !isCancelled) {
    			String temporalExpression = query.getKey();
    			// Reuse state space trick: we copy all the queries into a single string
    			if (view.isReuseStateSpace()) {
    				final String separator = System.lineSeparator();
    				StringBuilder queryBuilder = new StringBuilder(temporalExpression + separator);
    				while ((query = readLineSkipComments(reader)) != null && !isCancelled) {
    					queryBuilder.append(query.getKey() + separator);
    				}
    				temporalExpression = queryBuilder.delete(queryBuilder.lastIndexOf(separator), queryBuilder.length()).toString();
    			}
    			//
    			logger.log(Level.INFO, "Checking " + temporalExpression + "...");
    			verifier = new GuiVerifier(temporalExpression, false, view);
    			verifier.execute();
				int elapsedTime = 0;
				while (!verifier.isDone() && elapsedTime < TIMEOUT && !isCancelled) {
					Thread.sleep(SLEEP_INTERVAL);    			
					++elapsedTime;
				}
				if (verifier.isDone() && !verifier.isProcessCancelled() /*needed as cancellation does not interrupt this method*/) {
					String resultSentence = null;
					if (view.isReuseStateSpace()) {
						resultSentence = "Test generation has been finished.";
					}
					else {
    					String stateName = query.getValue();
    					ThreeStateBoolean result = verifier.get();
    					if (temporalExpression.equals("A[] not deadlock")) {
    						// Deadlock query
    						switch (result) {
    							case TRUE:
    								resultSentence = "No deadlock.";
    							break;
    							case FALSE:
    								resultSentence = "There can be deadlock in the system.";
    							break;
    							case UNDEF:
    								// Theoretically unreachable because of !cancelled
    								resultSentence = "Not determined if there can be deadlock.";
    							break;
    						}
    					}
    					else {
    						// Reachability query
    						String isReachableString  = null;
    						switch (result) {
								case TRUE:
									isReachableString = "reachable";
								break;
								case FALSE:
									isReachableString = "NOT reachable";
								break;
								case UNDEF:
    								// Theoretically unreachable because of !cancelled
									isReachableString = "undefined";
								break;
    						}
    						resultSentence = stateName + " is " + isReachableString + ".";
    					}
					}
					buffer.append(resultSentence + System.lineSeparator());
					logger.log(Level.INFO, resultSentence); // Removing temporal operator
				}
				else if (elapsedTime >= TIMEOUT) {
					logger.log(Level.INFO, "Timeout...");
				}
				// Important to cancel the process
				verifier.cancelProcess(true);
    		}
		} catch (Exception e) {
			view.handleVerificationExceptions(e);
		} finally {
			if (getController().getGeneratedTestVerifier() == this) {
				// Removing this object from the attributes
				getController().setGeneratedTestVerifier(null);
			}
			if (verifier != null && !verifier.isProcessCancelled()) {
				verifier.cancelProcess(true);
			}
			// Enabling the verification buttons
			view.setVerificationButtons(true);
		}
    	if (!isCancelled) {
    		// Writing this only if the process has not been cancelled
    		view.setVerificationLabel("Finished generation.");
    	}
    	if (buffer.length() > 0) {
    		DialogUtil.showInfo(buffer.toString());
    	}
    }
	
	public void cancelProcess() {
		isCancelled = true;
	}
	
	private Entry<String, String> readLineSkipComments(BufferedReader reader) throws IOException {
		final String COMMENT_START = "/*";
		final String COMMENT_END = "*/";
		String line = reader.readLine();
		String comment = "";
		if (line == null) {
			return null;
		}
		if (line.contains(COMMENT_START)) {
			if (line.contains(COMMENT_END)) {
				comment += line;
			}
			else {
				while (!(line = reader.readLine()).contains(COMMENT_END)) {
					comment += line;
				}
			}
			line = reader.readLine();
		}
		return new AbstractMap.SimpleEntry<String, String>(line, comment);    		
	}
	
}