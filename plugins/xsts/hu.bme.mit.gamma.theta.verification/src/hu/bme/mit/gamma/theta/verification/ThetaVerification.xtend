/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.util.InterruptableCallable
import hu.bme.mit.gamma.util.ThreadRacer
import hu.bme.mit.gamma.verification.util.AbstractVerification
//import hu.bme.mit.gamma.verification.util.AbstractVerifier.ExtendedResult
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File
import java.util.logging.Level
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.trace.util.TraceUtil

class ThetaVerification extends AbstractVerification {
	// Singleton
	public static final ThetaVerification INSTANCE = new ThetaVerification
	protected new() {}
	//
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	//
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	
	override Result execute(File modelFile, File queryFile, String[] arguments) {
		val fileName = modelFile.name
		val packageFileName = fileName.toUnhiddenFileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val queries = fileUtil.loadString(queryFile)
		
		var Result result = null
		//var ExtendedResult extRes = null
		
		for (query : queries.splitLines) {
			// Racing for every query separately
			val racer = new ThreadRacer<Result>
			val callables = <InterruptableCallable<Result>>newArrayList
			
			for (argument : arguments) {
				argument.sanitizeArgument
				
				val verifier = new ThetaVerifier
				callables += new InterruptableCallable<Result> {
					
					override Result call() {
						val currentThread = Thread.currentThread
						logger.log(Level.INFO, '''Starting Theta on thread «currentThread.name» with "«argument»"''')
						val result = verifier.verifyQuery(gammaPackage, argument, modelFile, queries)
						logger.log(Level.INFO, '''Thread «currentThread.name» with "«argument»" has won''')
						//val trace = result.trace
						//traceUtil.addComment(trace, query)
						//traceUtil.sortInstanceStates(trace)
						//val traceFile = ecoreUtil.getFile(trace.eResource()) as File
						logger.log(Level.WARNING, '''DEBUG ThetaVerification:61 - arguments «argument»''')
						return result
					}
					
					override void cancel() {
						verifier.cancel
						logger.log(Level.INFO, '''Theta verification instance with "«argument»" has been cancelled''')
					}
					
				}
			}
			
			/*for (InterruptableCallable<Result> c : callables) {
				val res = c.call()
				var i = 0
			}*/
			
			val newResult = racer.execute(callables)
			
			if (result === null) {
				result = newResult
			}
			else {
				result = result.extend(newResult)
			}
		}
		logger.log(Level.WARNING, '''DEBUG ThetaVerification:87 - return execute()''')
		return result
	}
	
	override getDefaultArguments() {
		return #[
				"",
				"--domain EXPL --refinement SEQ_ITP --maxenum 250 --initprec CTRL",
				"--domain EXPL_PRED_COMBINED --autoexpl NEWOPERANDS --initprec CTRL"
			]
		// --domain PRED_CART --refinement SEQ_ITP // default - cannot be used with loops
		// --domain EXPL --refinement SEQ_ITP --maxenum 250 // --initprec CTRL should be used to support loops
		// --domain EXPL_PRED_COMBINED --autoexpl NEWOPERANDS --initprec CTRL
	}
	
	protected override String getArgumentPattern() {
		return "(--[a-z]+( )[_0-9A-Z]+( )*)*"
	}
	
}