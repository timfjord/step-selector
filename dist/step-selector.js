(function() {
  angular.module('step-selector', []);

  angular.module('step-selector').factory('StepSelector', function() {
    var StepSelector;
    return StepSelector = (function() {
      function StepSelector(conditions) {
        this._conditions = [];
        this._current = 1;
        this._events = {};
        this._locked = false;
        this._lockedSteps = [];
        this._stepsHistory = [1];
        if (conditions) {
          this.addConditions(conditions);
        }
      }

      StepSelector.prototype.currentStep = function() {
        return this._current;
      };

      StepSelector.prototype.isCurrentStep = function() {
        var i, len, result, step;
        result = false;
        for (i = 0, len = arguments.length; i < len; i++) {
          step = arguments[i];
          result = result || this._current === step;
        }
        return result;
      };

      StepSelector.prototype.isCurrentStepInRange = function(min, max) {
        if (!(min && max)) {
          throw new Error('Edges are required');
        }
        min = parseInt(min);
        max = parseInt(max);
        if (isNaN(min) || isNaN(max)) {
          throw new Error('Edges are required');
        }
        if (min > max) {
          throw new Error('min should be less than max');
        }
        return this._current >= min && this._current <= max;
      };

      StepSelector.prototype.addConditions = function(conditions) {
        var condition, i, len, results;
        if (angular.isArray(conditions)) {
          results = [];
          for (i = 0, len = conditions.length; i < len; i++) {
            condition = conditions[i];
            results.push(this.addCondition(condition));
          }
          return results;
        }
      };

      StepSelector.prototype.addCondition = function(condition) {
        if (!angular.isFunction(condition)) {
          throw new Error('Condtition should be function');
        }
        return this._conditions.push(condition);
      };

      StepSelector.prototype.evalConditions = function() {
        var f, i, len, ref, results;
        ref = this._conditions;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          f = ref[i];
          results.push(f.call());
        }
        return results;
      };

      StepSelector.prototype.isSuccessCondition = function(value) {
        return value && value !== '';
      };

      StepSelector.prototype.isStepAvailable = function(step) {
        var prevNotEmptyValue, prevValues, value;
        step = parseInt(step);
        if (isNaN(step)) {
          throw new Error('Step should be an integer');
        }
        if (step < 1) {
          return false;
        }
        prevValues = this.evalConditions().slice(0, step - 1);
        prevNotEmptyValue = (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = prevValues.length; i < len; i++) {
            value = prevValues[i];
            if (this.isSuccessCondition(value)) {
              results.push(value);
            }
          }
          return results;
        }).call(this);
        return prevNotEmptyValue.length === prevValues.length;
      };

      StepSelector.prototype.isAllStepsAvailable = function() {
        return this.isStepAvailable(this._conditions.length + 1);
      };

      StepSelector.prototype.isPrevStepAvailable = function() {
        return this.isStepAvailable(this._current - 1);
      };

      StepSelector.prototype.isNextStepAvailable = function() {
        return this.isStepAvailable(this._current + 1);
      };

      StepSelector.prototype.isVisitedStep = function(step) {
        return this._stepsHistory.indexOf(step) !== -1;
      };

      StepSelector.prototype.lock = function() {
        return this._locked = true;
      };

      StepSelector.prototype.unlock = function() {
        return this._locked = false;
      };

      StepSelector.prototype.lockStep = function(step) {
        return this._lockedSteps.push(step);
      };

      StepSelector.prototype.unlockStep = function(step) {
        var index;
        index = this._lockedSteps.indexOf(step);
        if (index !== -1) {
          return this._lockedSteps.splice(index, 1);
        }
      };

      StepSelector.prototype.goTo = function(step) {
        var fromStep;
        if (!this._locked && this._lockedSteps.indexOf(step) === -1 && step <= this._conditions.length && this.isStepAvailable(step)) {
          fromStep = this._current;
          this._current = step;
          this._stepsHistory.push(step);
          return this.trigger('goTo', [this._current, fromStep]);
        }
      };

      StepSelector.prototype.prevStep = function() {
        return this.goTo(this._current - 1);
      };

      StepSelector.prototype.nextStep = function() {
        return this.goTo(this._current + 1);
      };

      StepSelector.prototype.goToTheLatestAvailableStep = function() {
        var condition, i, index, latestAvailableStep, len, ref;
        latestAvailableStep = 1;
        ref = this.evalConditions();
        for (index = i = 0, len = ref.length; i < len; index = ++i) {
          condition = ref[index];
          if (this.isSuccessCondition(condition)) {
            latestAvailableStep = index + 1;
            this._stepsHistory.push(latestAvailableStep);
          } else {
            break;
          }
        }
        return this.goTo(Math.min(latestAvailableStep + 1, this._conditions.length));
      };

      StepSelector.prototype.on = function(event, callback) {
        if (!this._events[event]) {
          this._events[event] = [];
        }
        return this._events[event].push(callback);
      };

      StepSelector.prototype.trigger = function(event, args) {
        var callback, i, len, ref, results;
        ref = this._events[event] || [];
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          callback = ref[i];
          if (angular.isFunction(callback)) {
            results.push(callback.apply(this, args));
          }
        }
        return results;
      };

      return StepSelector;

    })();
  });

}).call(this);
