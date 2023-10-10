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
package hu.bme.mit.gamma.codegeneration.java

import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.util.GammaEcoreUtil
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*

class NameGenerator {
	//
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	//
	protected final String PACKAGE_NAME

	new(String packageName) {
		this.PACKAGE_NAME = packageName
	}

	/**
	 * Returns the Java package name of the class generated from the component.
	 */
	def generateComponentPackageName (Component component) '''«PACKAGE_NAME».«component.containingPackage.name.toLowerCase»'''
	def generateObjectPackageName (EObject object) '''«PACKAGE_NAME».«object.getContainerOfType(Package).name.toLowerCase»'''

	/**
	 * Returns the name of the Java channel interface generated from the given Gamma interface. 
	 */
	def generateChannelName(Interface anInterface) {
		return anInterface.name.toFirstUpper + "Channel"
	}
	
	/**
	 * Returns the name of the Java channel interface generated from the given Gamma interface. 
	 */
	def generateChannelInterfaceName(Interface anInterface) {
		return anInterface.generateChannelName + "Interface"
	}
	
	/**
	 * Returns the name of the Java class of the component.
	 */
	def generateComponentClassName(Component component) {
		return component.componentClassName
	}
	
	/**
	 * Returns the name of the Yakindu statemachine the given component is transformed from.
	 * They use it for package namings. It does not contain the "Statemachine" suffix."
	 */
	def getYakinduStatemachineName(Component component) {
		return component.name
	}
	
	/**
	 * Returns the name of the statemachine class generated by Yakindu.
	 */
	def getStatemachineClassName(Component component) {
		return component.yakinduStatemachineName + "Statemachine"
	}
	
	/**
	 * Returns the name of the wrapped Yakindu statemachine instance.
	 */
	def generateStatemachineInstanceName(Component component) {
		return component.statemachineClassName.toFirstLower
	}
	
	/**
	 * Returns the name of the wrapped synchronous component instance.
	 */
	def generateWrappedComponentName(AsynchronousAdapter wrapper) {
		return wrapper.wrappedComponent.name
	}
	
	/**
	 * Returns the interface name (implemented by the component) of the given component.
	 */
	def generatePortOwnerInterfaceName(Component component) {
		return component.generateComponentClassName + "Interface";
	}
	
	/**
	 * Returns the type name of the interface of the wrapped Yakindu statemachine.
	 */
	def getYakinduInterfaceName(Port port) {
		 if (port.name === null) {
		 	return "SCInterface"
		 }
		 return "SCI" + port.name.toFirstUpper
	} 
	
	/**
	 * Returns the containing package of a component.
	 */
	def getContainingPackage(Component component) {
		return component.eContainer as Package
	}
	
}