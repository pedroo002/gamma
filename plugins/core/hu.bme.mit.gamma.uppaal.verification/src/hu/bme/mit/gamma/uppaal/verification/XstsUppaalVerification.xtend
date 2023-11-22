/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File
import hu.bme.mit.gamma.util.FileUtil

class XstsUppaalVerification extends AbstractUppaalVerification {
	// Singleton
	public static final XstsUppaalVerification INSTANCE = new XstsUppaalVerification
	protected new() {}
	//
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	//
	
	override Result execute(File modelFile, File queryFile, String[] arguments) {
		val fileName = modelFile.name
		val packageFileName = fileName.toUnhiddenFileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val verifier = new UppaalVerifier
		val argument = arguments.head
		
		argument.sanitizeArgument
		
		return verifier.verifyQuery(gammaPackage, argument, modelFile, queryFile)
	}
	
	override getDefaultArguments() {
		return #[ "-C -T -t0" ]
	}

}