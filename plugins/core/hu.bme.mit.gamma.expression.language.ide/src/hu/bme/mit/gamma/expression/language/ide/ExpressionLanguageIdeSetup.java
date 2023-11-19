/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.expression.language.ide;

import org.eclipse.xtext.util.Modules2;

import com.google.inject.Guice;
import com.google.inject.Injector;

import hu.bme.mit.gamma.expression.language.ExpressionLanguageRuntimeModule;
import hu.bme.mit.gamma.expression.language.ExpressionLanguageStandaloneSetup;

/**
 * Initialization support for running Xtext languages as language servers.
 */
public class ExpressionLanguageIdeSetup extends ExpressionLanguageStandaloneSetup {

	@Override
	public Injector createInjector() {
		return Guice.createInjector(Modules2.mixin(new ExpressionLanguageRuntimeModule(), new ExpressionLanguageIdeModule()));
	}
	
}
