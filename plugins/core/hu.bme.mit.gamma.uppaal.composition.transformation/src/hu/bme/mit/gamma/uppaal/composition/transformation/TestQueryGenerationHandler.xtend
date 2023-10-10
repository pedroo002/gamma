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
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.transformation.util.queries.TopSyncSystemOutEvents
import hu.bme.mit.gamma.uppaal.composition.transformation.ModelModifierForTestGeneration.InteractionRepresentation
import hu.bme.mit.gamma.uppaal.util.Namings
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.Set

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class TestQueryGenerationHandler {
	// Has to be set externally
	ModelModifierForTestGeneration modelModifier
	InteractionRepresentation interactionRepresentation = InteractionRepresentation.UNDER_APPROXIMATION
	// Auxiliary
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	// State coverage
	protected boolean STATE_COVERAGE
	protected final Set<SynchronousComponentInstance> stateCoverableComponents = newHashSet
	// Transition coverage
	protected boolean TRANSITION_COVERAGE
	protected final Set<SynchronousComponentInstance> transitionCoverableComponents = newHashSet
	// Out-event coverage
	protected boolean OUT_EVENT_COVERAGE
	protected final Set<SynchronousComponentInstance> outEventCoverableComponents = newHashSet
	// Interaction coverage
	protected boolean INTERACTION_COVERAGE
	protected final Set<SynchronousComponentInstance> interactionCoverableComponents = newHashSet
	
	new(Collection<SynchronousComponentInstance> stateCoverableComponents,
			Collection<SynchronousComponentInstance> transitionCoverableComponents,
			Collection<SynchronousComponentInstance> outEventCoverableComponents,
			Collection<SynchronousComponentInstance> interactionCoverableComponents) {
		if (!stateCoverableComponents.empty) {
			this.STATE_COVERAGE = true
			this.stateCoverableComponents += stateCoverableComponents
		}
		if (!transitionCoverableComponents.empty) {
			this.TRANSITION_COVERAGE = true
			this.transitionCoverableComponents += transitionCoverableComponents
		}
		if (!outEventCoverableComponents.empty) {
			this.OUT_EVENT_COVERAGE = true
			this.outEventCoverableComponents += outEventCoverableComponents
		}
		if (!interactionCoverableComponents.empty) {
			this.INTERACTION_COVERAGE = true
			this.interactionCoverableComponents += interactionCoverableComponents
		}
	}
	
	def setInteractionRepresentation(InteractionRepresentation interactionRepresentation) {
		this.interactionRepresentation = interactionRepresentation
	}
	
	/**
	 * Has to be called externally.
	 */
	def setModelModifier(ModelModifierForTestGeneration modelModifierForTestGeneration) {
		this.modelModifier = modelModifierForTestGeneration
		this.modelModifier.setComponentInstances(transitionCoverableComponents,
			interactionCoverableComponents)
		this.modelModifier.interactionRepresentation = interactionRepresentation
	}
	
	def getModelModifier() {
		return this.modelModifier
	}

	// Deadlock

	def String generateDeadlockExpression() {
		return '''A[] not deadlock«System.lineSeparator»'''
	}
	
	// State coverage
	
	def String generateStateCoverageExpressions() {
		val expressions = new StringBuilder
		// VIATRA matches cannot be used here, as testedComponentsForStates has different pointers for some reason
		for (instance : stateCoverableComponents) {
			val statechart = instance.type as StatechartDefinition
			val regions = newHashSet
			regions += statechart.allRegions
			for (region : regions) {
				val templateName = region.getTemplateName(instance)
				val processName = templateName.processName
				for (state : region.stateNodes.filter(State)) {
					val locationName = state.locationName
					if (templateName.hasLocation(locationName)) {
						expressions.append('''/*«System.lineSeparator»«instance.name»: «region.name».«state.name»«System.lineSeparator»*/«System.lineSeparator»''')
						expressions.append('''E<> «processName».«locationName» && «Namings.isStableVariableName»«System.lineSeparator»''')
					}
				}
			}
		}
		return expressions.toString
	}
	
	private def hasLocation(String templateName, String locationName) {
		if (modelModifier !== null) {
			val nta = modelModifier.nta
			val templates = nta.template.filter[it.name == templateName]
			checkState(templates.size == 1, templates + " " + templateName + " " + locationName)
			val template = templates.head
			if (template !== null) {
				return template.location.exists[it.name == locationName]
			}
		}
		return false
	}
	
	// Transition coverage
	
	private def getName(Transition transition) {
		return transition.sourceState.name + "-->" + transition.targetState.name
	}
	
	def String generateTransitionCoverageExpressions() {
		val expressions = new StringBuilder
		// VIATRA matches cannot be used here, as testedComponentsForStates has different pointers for some reason
		for (entry : modelModifier.transitionAnnotations.entrySet) {
			val transition = entry.key
			val id = entry.value
			val statechart = transition.containingStatechart
			val instance = transitionCoverableComponents.findFirst[it.type === statechart]
			expressions.append('''/*«System.lineSeparator»«instance.name»: «transition.name»«System.lineSeparator»*/«System.lineSeparator»''')
			// Suffix present? If not, all transitions can be reached; if yes, some transitions
			// are covered by transition fired in the same step, but the end is a stable state
			expressions.append('''E<> «transitionIdVariableName» == «id» && «Namings.isStableVariableName»«System.lineSeparator»''')
		}
		return expressions.toString
	}
	
	// Out event coverage
	
	def String generateOutEventCoverageExpressions() {
		val expressions = new StringBuilder
		// VIATRA matches cannot be used here, as testedComponentsForStates has different pointers for some reason
		val outEventMatches = TopSyncSystemOutEvents.Matcher.on(modelModifier.engine).allMatches
			.filter[outEventCoverableComponents.contains(it.instance)]
		for (outEventMatch : outEventMatches) {
			val systemPort = outEventMatch.systemPort
			val port = outEventMatch.port
			val event = outEventMatch.event
			val parameters = event.parameterDeclarations
			val parameterValues = newHashMap
			if (!parameters.empty) {
				for (parameter : parameters) {
					val typeDefinition = parameter.type.typeDefinition
					switch (typeDefinition) {
						// Checking only booleans and enumerations now
						BooleanTypeDefinition: {
							parameterValues.put(parameter, #{"true", "false"})
						}
						EnumerationTypeDefinition : {
							parameterValues.put(parameter, typeDefinition.literals.map[typeDefinition.literals.indexOf(it).toString])
						}
					}
				}
			}
			val instance = outEventMatch.instance
			val outEventVariableName = Namings.getOutEventName(event, port, instance)
			if (parameterValues.empty) {
				expressions.append('''/*«System.lineSeparator»«systemPort.name».«event.name»«System.lineSeparator»*/«System.lineSeparator»''')
				expressions.append('''E<> «outEventVariableName» == true && «Namings.isStableVariableName»«System.lineSeparator»''')
			}
			else {
				for (parameter : parameters) {
					val parameterVariableName = Namings.getOutValueOfName(event, port, parameter, instance)
					for (parameterValue : parameterValues.get(parameter)) {
						expressions.append('''/*«System.lineSeparator»«systemPort.name».«event.name»«System.lineSeparator»*/«System.lineSeparator»''')
						expressions.append('''E<> «outEventVariableName» == true && «parameterVariableName» == «parameterValue» && «Namings.isStableVariableName»«System.lineSeparator»''')
					}
				}
			}
		}
		return expressions.toString
	}
	
	// Transition coverage
	
	private def getSendingObjectName(RaiseEventAction action) {
		val transition = action.getContainerOfType(Transition)
		if (transition === null) {
			val state = action.getContainerOfType(State)
			if (state === null) {
				throw new IllegalArgumentException("Not known raise event: " + action)
			}
			return state.name
		}
		return transition.name
	}
	
	def String generateInteractionCoverageExpressions() {
		val expressions = new StringBuilder
		// VIATRA matches cannot be used here, as testedComponentsForStates has different pointers for some reason
		for (entry : modelModifier.getInteractionIds.entrySet) {
			val outInstance = entry.key
			val actionMap = entry.value
			for (actionEntry : actionMap.entrySet) {
				val action = actionEntry.key
				val actionContainerName = action.sendingObjectName
				val interactionIds = actionEntry.value
				val sendingId = interactionIds.key
				val receivingIds = interactionIds.value
				for (receivingIdEntry : receivingIds) {
					val receivingId = receivingIdEntry.key
					val receivingTransition = receivingIdEntry.value
					val inStatechart = receivingTransition.containingStatechart
					val inInstance = interactionCoverableComponents.findFirst[it.type === inStatechart]
					expressions.append('''/*«System.lineSeparator»«outInstance.name»: «actionContainerName» -i-> «inInstance.name»: «receivingTransition.name»«System.lineSeparator»*/«System.lineSeparator»''')
					// Suffix present? If not, all transitions can be reached; if yes, some transitions
					// are covered by transition fired in the same step, but the end is a stable state
					expressions.append('''E<> «outInstance.sendingInteractionIdVariableName» == «sendingId» && «inInstance.receivingInteractionIdVariableName» == «receivingId» && «Namings.isStableVariableName»«System.lineSeparator»''')
				}
			}
		}
		return expressions.toString
	}
	
	def generateExpressions() {
		val expressions = new StringBuilder
		expressions.append(generateDeadlockExpression)
		if (STATE_COVERAGE) {
			expressions.append(generateStateCoverageExpressions)
		}
		if (TRANSITION_COVERAGE) {
			expressions.append(generateTransitionCoverageExpressions)
		}
		if (OUT_EVENT_COVERAGE) {
			expressions.append(generateOutEventCoverageExpressions)
		}
		if (INTERACTION_COVERAGE) {
			expressions.append(generateInteractionCoverageExpressions)
		}
		return expressions.toString
	}
	
}