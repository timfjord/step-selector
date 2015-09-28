angular.module('step-selector').factory 'StepSelector', ->
  class StepSelector
    constructor: (conditions) ->
      @_conditions = []
      @_current = 1
      @_events = {}
      @_locked = false
      @_lockedSteps = []
      @_stepsHistory = [1]

      @addConditions conditions if conditions

    currentStep: -> @_current

    isCurrentStep: ->
      result = false
      result = result || @_current == step for step in arguments
      result

    isCurrentStepInRange: (min, max) ->
      unless min && max
        throw new Error('Edges are required')

      min = parseInt min
      max = parseInt max
      if isNaN(min) || isNaN(max)
        throw new Error('Edges are required')

      if min > max
        throw new Error('min should be less than max')

      @_current >= min && @_current <= max

    addConditions: (conditions) ->
      if angular.isArray conditions
        @addCondition condition for condition in conditions

    addCondition: (condition) ->
      throw new Error('Condtition should be function') unless angular.isFunction condition
      @_conditions.push condition

    evalConditions: ->
      (f.call() for f in @_conditions)

    isSuccessCondition: (value) ->
      value && value != ''

    isStepAvailable: (step) ->
      step = parseInt step
      throw new Error('Step should be an integer') if isNaN(step)

      return false if step < 1

      prevValues = @evalConditions().slice 0, step - 1
      prevNotEmptyValue = (value for value in prevValues when @isSuccessCondition(value))

      prevNotEmptyValue.length == prevValues.length

    isAllStepsAvailable: -> @isStepAvailable @_conditions.length + 1

    isPrevStepAvailable: -> @isStepAvailable @_current - 1

    isNextStepAvailable: -> @isStepAvailable @_current + 1

    isVisitedStep: (step) -> @_stepsHistory.indexOf(step) != -1

    lock: -> @_locked = true

    unlock: -> @_locked = false

    lockStep: (step) -> @_lockedSteps.push step

    unlockStep: (step) ->
      index = @_lockedSteps.indexOf step
      @_lockedSteps.splice index, 1 if index != -1

    goTo: (step) ->
      if !@_locked && @_lockedSteps.indexOf(step) == -1 && step <= @_conditions.length && @isStepAvailable step
        fromStep = @_current
        @_current = step
        @_stepsHistory.push step
        @trigger 'goTo', [@_current, fromStep]

    prevStep: -> @goTo @_current - 1

    nextStep: -> @goTo @_current + 1

    goToTheLatestAvailableStep: ->
      latestAvailableStep = 1
      for condition, index in @evalConditions()
        if @isSuccessCondition(condition)
          latestAvailableStep = index + 1
          @_stepsHistory.push latestAvailableStep
        else
          break

       @goTo Math.min(latestAvailableStep + 1, @_conditions.length)

    on: (event, callback) ->
      @_events[event] = [] unless @_events[event]
      @_events[event].push callback

    trigger: (event, args) ->
      callback.apply(this, args) for callback in (@_events[event] || []) when angular.isFunction callback
