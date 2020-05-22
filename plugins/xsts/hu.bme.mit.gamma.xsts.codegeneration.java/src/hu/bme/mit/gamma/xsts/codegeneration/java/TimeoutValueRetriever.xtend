package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.model.SetTimeoutAction
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.TimeSpecification
import hu.bme.mit.gamma.statechart.model.TimeUnit
import hu.bme.mit.gamma.statechart.model.TimeoutDeclaration
import java.math.BigInteger
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil.Copier

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class TimeoutValueRetriever {
	
	extension ExpressionModelFactory constraintModelFactory = ExpressionModelFactory.eINSTANCE
	
	def getStateOfTimeout(TimeoutDeclaration timeoutDeclaration) {
		val gammaStatechart = timeoutDeclaration.getContainingStatechart
		val gammaStates = gammaStatechart.allStates
		val actions = (gammaStates.map[it.entryActions] + gammaStates.map[it.exitActions]).flatten
		val timeoutSettings = actions.filter(SetTimeoutAction)
		val correctTimeoutSetting = timeoutSettings.filter[it.timeoutDeclaration == timeoutDeclaration]
		checkState(correctTimeoutSetting.size == 1, "Not one setting to the same timeout declaration: " + correctTimeoutSetting)
		// Single assignment, expected branch
		val parentState = correctTimeoutSetting.head.eContainer as State
		return parentState
	}
	
	def Expression getValueOfTimeout(TimeoutDeclaration timeoutDeclaration) {
		val gammaStatechart = timeoutDeclaration.getContainingStatechart
		val gammaTransitions = gammaStatechart.transitions
		val gammaStates = gammaStatechart.allStates
		val actions = (gammaTransitions.map[it.effects] + gammaStates.map[it.entryActions] + gammaStates.map[it.exitActions]).flatten
		val timeoutSettings = actions.filter(SetTimeoutAction)
		val correctTimeoutSetting = timeoutSettings.filter[it.timeoutDeclaration == timeoutDeclaration]
		checkState(correctTimeoutSetting.size == 1, "Not one setting to the same timeout declaration: " + correctTimeoutSetting)
		// Single assignment, expected branch
		return correctTimeoutSetting.head.time.transform
	}
	
	private def Expression transform(TimeSpecification time) {
		val timeValue = time.value.clone
		val timeUnit = time.unit
		switch (timeUnit) {
			case TimeUnit.SECOND: {
				// S = 1000 MS
				return createMultiplyExpression => [
					it.operands += createIntegerLiteralExpression => [
						it.value = BigInteger.valueOf(1000)
					]
					it.operands += timeValue
				]
			}
			default: {
				// MS is base
				return timeValue
			}
		}
	}
		
	private def <T extends EObject> T clone(T element) {
		// A new copier should be used every time, otherwise anomalies happen (references are changed without asking)
		val copier = new Copier(true, true)
		val clone = copier.copy(element) as T;
		copier.copyReferences();
		return clone;
	}
	
}