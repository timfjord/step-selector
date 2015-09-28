describe 'StepSelector', ->
  beforeEach module('step-selector')

  StepSelector = stepSelector = null

  beforeEach inject (_StepSelector_) ->
    StepSelector = _StepSelector_
    stepSelector = new StepSelector()

  it 'should set step 1 by default', ->
    expect(stepSelector.isCurrentStep(1)).toBeTruthy()

  describe '.addConditions', ->
    it 'should allow array conditions', ->
      stepSelector.addCondition = jasmine.createSpy()
      stepSelector.addConditions 1
      expect(stepSelector.addCondition).not.toHaveBeenCalled()

      stepSelector.addConditions [1]
      expect(stepSelector.addCondition).toHaveBeenCalled()

  describe '.addCondition', ->
    it 'should throw error for non function arguments', ->
      expect(-> stepSelector.addCondition 1).toThrowError 'Condtition should be function'

  describe '.evalConditions', ->
    it 'should return array with eval conditions', ->
      stepSelector.addCondition -> 1
      expect(stepSelector.evalConditions()).toEqual [1]

  describe '.isStepAvailable', ->
    it 'should be falsy is step less than one', ->
      expect(stepSelector.isStepAvailable(0)).toBeFalsy()

    it 'should throw error if step cannot be parsed as integer', ->
      expect(-> stepSelector.isStepAvailable('first')).toThrowError 'Step should be an integer'

    it 'should be always truthy for first step', ->
      expect(stepSelector.isStepAvailable(1)).toBeTruthy()

    it 'should be truthy if all previous conditions present(true, not emprt string)', ->
      stepSelector.addCondition(-> true)
      expect(stepSelector.isStepAvailable(2)).toBeTruthy()

    it 'should be falsy if at least one previous condition is negative(false, empty string, undefined)', ->
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> false)

      expect(stepSelector.isStepAvailable(2)).toBeTruthy()
      expect(stepSelector.isStepAvailable(3)).toBeFalsy()

  describe '.isAllStepsAvailable', ->
    it 'should be truthy is all condition is present', ->
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> true)
      expect(stepSelector.isAllStepsAvailable()).toBeTruthy()

      stepSelector.addCondition(-> false)
      expect(stepSelector.isAllStepsAvailable()).toBeFalsy()

  describe '.goTo', ->
    it 'should always allow go to first step', ->
      stepSelector.addCondition(-> false)
      stepSelector.addCondition(-> false)

      stepSelector.goTo 1

      expect(stepSelector.isCurrentStep(1)).toBeTruthy()

    it 'should change current step only if step is available', ->
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> false)

      stepSelector.goTo 2
      expect(stepSelector.isCurrentStep(2)).toBeTruthy()

      stepSelector.goTo 3
      expect(stepSelector.isCurrentStep(3)).toBeFalsy()

    it 'should stay on same step if passed step out of range', ->
      stepSelector.goTo 2
      expect(stepSelector.isCurrentStep(1)).toBeTruthy()

      stepSelector.goTo 0
      expect(stepSelector.isCurrentStep(1)).toBeTruthy()

  describe 'events', ->
    describe 'goTo event', ->
      it 'triggers when calling goTo and pass toState and fromState as event arguments', ->
        event =
          callback: (toStep, fromStep) ->
            expect(toStep).toEqual(2)
            expect(fromStep).toEqual(1)
        spyOn(event, 'callback').and.callThrough()
        stepSelector.addCondition(-> true)
        stepSelector.addCondition(-> true)
        stepSelector.on 'goTo', event.callback

        stepSelector.goTo 2
        expect(event.callback).toHaveBeenCalled()

  describe '.currentStep', ->
    it 'should return current step', ->
      expect(stepSelector.currentStep()).toEqual(1)

      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> true)
      stepSelector.goTo 2
      expect(stepSelector.currentStep()).toEqual(2)

  describe '.prevStep', ->
    it 'should go to previous step', ->
      stepSelector.addCondition(-> true)
      stepSelector.goTo 2

      stepSelector.prevStep()
      expect(stepSelector.currentStep()).toEqual(1)

  describe '.nextStep', ->
    it 'should go to next step if available', ->
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> false)

      stepSelector.nextStep()
      expect(stepSelector.currentStep()).toEqual(2)

      stepSelector.nextStep()
      expect(stepSelector.currentStep()).not.toEqual(3)

    it 'should stay on first step if current step is 1', ->
      expect(stepSelector.currentStep()).toEqual(1)

      stepSelector.prevStep()
      expect(stepSelector.currentStep()).toEqual(1)

  describe '.isPrevStepAvailable', ->
    it 'should check if previous state avaialbe', ->
      expect(stepSelector.isPrevStepAvailable()).toBeFalsy()

      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> true)
      stepSelector.goTo 2
      expect(stepSelector.isPrevStepAvailable()).toBeTruthy()

  describe '.isNextStepAvailable', ->
    it 'should check if next state avaialbe', ->
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> false)
      expect(stepSelector.isNextStepAvailable()).toBeTruthy()

      stepSelector.goTo 2
      expect(stepSelector.isNextStepAvailable()).toBeFalsy()

  describe '.isCurrentStepInRange', ->
    it 'should throw error if no value passed or no edges detected', ->
      expect(-> stepSelector.isCurrentStepInRange()).toThrowError 'Edges are required'
      expect(-> stepSelector.isCurrentStepInRange(1)).toThrowError 'Edges are required'
      expect(-> stepSelector.isCurrentStepInRange(2, 1)).toThrowError 'min should be less than max'

    it 'should recognize if current step is in pased range', ->
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> true)

      stepSelector.goTo 3

      expect(stepSelector.currentStep()).toEqual(3)
      expect(stepSelector.isCurrentStepInRange(1, 2)).toBeFalsy()
      expect(stepSelector.isCurrentStepInRange(1, 3)).toBeTruthy()
      expect(stepSelector.isCurrentStepInRange(2, 3)).toBeTruthy()
      expect(stepSelector.isCurrentStepInRange(3, 10)).toBeTruthy()
      expect(stepSelector.isCurrentStepInRange(4, 10)).toBeFalsy()

  describe '.isSuccessCondition', ->
    it 'should check if value is success', ->
      expect(stepSelector.isSuccessCondition(false)).toBeFalsy()
      expect(stepSelector.isSuccessCondition(null)).toBeFalsy()
      expect(stepSelector.isSuccessCondition(undefined)).toBeFalsy()
      expect(stepSelector.isSuccessCondition('')).toBeFalsy()
      expect(stepSelector.isSuccessCondition(true)).toBeTruthy()
      expect(stepSelector.isSuccessCondition({})).toBeTruthy()
      expect(stepSelector.isSuccessCondition('a')).toBeTruthy()
      expect(stepSelector.isSuccessCondition(1)).toBeTruthy()

  describe '.goToTheLatestAvailableStep', ->
    it 'should to to the latest available step', ->
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> false)
      stepSelector.addCondition(-> true)

      stepSelector.goToTheLatestAvailableStep()

      expect(stepSelector.currentStep()).toEqual(4)

  describe '.lock', ->
    it 'should prevent change step', ->
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> true)
      stepSelector.goTo 3
      expect(stepSelector.currentStep()).toEqual(3)

      stepSelector.lock()
      stepSelector.goTo 3
      expect(stepSelector.currentStep()).toEqual(3)

  describe '.isCurrentStep', ->
    it 'should detect if passed step is current', ->
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> true)
      stepSelector.goTo 2
      expect(stepSelector.isCurrentStep(2)).toBeTruthy()
      expect(stepSelector.isCurrentStep(1)).toBeFalsy()

    it 'should support array', ->
      stepSelector.addCondition(-> true)
      stepSelector.addCondition(-> true)
      stepSelector.goTo 2
      expect(stepSelector.isCurrentStep(1, 2, 5)).toBeTruthy()
      expect(stepSelector.isCurrentStep(1)).toBeFalsy()
