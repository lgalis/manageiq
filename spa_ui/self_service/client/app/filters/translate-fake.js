// a fake translate filter that returns identity - to prevent our templates from drifting apart from upstream too much

(function() {
  'use strict';
  angular.module('app.services').filter('translate', function() {
    return angular.identity;
  });
})();
