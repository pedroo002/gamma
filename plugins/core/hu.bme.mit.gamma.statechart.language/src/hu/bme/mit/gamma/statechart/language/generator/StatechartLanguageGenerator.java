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
package hu.bme.mit.gamma.statechart.language.generator;

import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.generator.AbstractGenerator;
import org.eclipse.xtext.generator.IFileSystemAccess2;
import org.eclipse.xtext.generator.IGeneratorContext;

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
public class StatechartLanguageGenerator extends AbstractGenerator {

	@Override
	public void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
//		Iterator<Greeting> filtered = Iterators.filter(resource.getAllContents(), Greeting.class);
//		Iterator<String> names = Iterators.transform(filtered, new Function<Greeting, String>() {
//
//			@Override
//			public String apply(Greeting greeting) {
//				return greeting.getName();
//			}
//		});
//		fsa.generateFile("greetings.txt", "People to greet: " + IteratorExtensions.join(names, ", "));
	}
}
