/*
Controller for interface "$interfaceName$" (context: "$contextName$"). Generated code, edit with care.
Generated by $ampersandVersionStr$

INTERFACE "$interfaceName$" : $expAdl$ :: $source$ * $target$  ($if(!isRoot)$non-$endif$root interface)
Roles: [$roles;separator=", "$]
Editable relations: [$editableRelations;separator=", "$] 
*/

AmpersandApp.controller('$interfaceIdent$Controller', function (\$scope, \$rootScope, \$routeParams, Restangular, \$location) {
  
  \$scope.val = {};
  // URL to the interface API. 'http://pathToApp/api/v1/' is already configured elsewhere.
  url = 'interface/$interfaceName$';
  
  // Only insert code below if interface is allowed to create new atoms. This is not specified in interfaces yet, so add by default
  if(\$routeParams['new']){
    newAtom = Restangular.one(url).post().then(function (data){
      \$scope.val['$interfaceName$'] = Restangular.restangularizeCollection('', data, url);
    });
  }else
  
  // Checks if resourceId is provided, and if so does a get() else a getList()
  if(typeof \$routeParams.resourceId != 'undefined'){
    list = Restangular.one(url, \$routeParams.resourceId).get().then(function(data){
      \$scope.val['$interfaceName$'] = Restangular.restangularizeCollection('', data, url);
    });
  }else{
    \$scope.val['$interfaceName$'] = Restangular.all(url).getList().\$object;
  }


  // The function below is only necessary if the interface allows to delete the complete atom,
  // but since this cannot be specified yet in Ampersand we always include it.

  // Delete function to delete a complete Resource
  \$scope.deleteResource = function (ResourceId){
    if(confirm('Are you sure?')){
      \$scope.val['$interfaceName$'][ResourceId]
        .remove()
        .then(function(data){
          \$rootScope.updateNotifications(data.notifications);
          \$location.url('/');
        });
    }
  }
   
$if(containsDATE)$  // The interface contains an editable relation to the primitive concept DATE
  // Function for Datepicker
  \$scope.datepicker = []; // empty array to administer if datepickers (can be multiple on one page) are open and closed
  \$scope.openDatepicker = function(\$event, datepicker) {
    \$event.preventDefault();
    \$event.stopPropagation();
    
    \$scope.datepicker[datepicker] = {'open' : true};
  }
$else$  // The interface does not contain editable relations to primitive concept DATE
$endif$
$if(containsEditable)$  // The interface contains at least 1 editable relation
  // Patch function to update a Resource
  \$scope.patch = function(ResourceId){
    \$scope.val['$interfaceName$'][ResourceId]
      .patch()
      .then(function(data) {
        \$rootScope.updateNotifications(data.notifications);
        \$scope.val['$interfaceName$'][ResourceId] = Restangular.restangularizeElement('', data.content, url);
      });
  }
  
  // Function to add item to array of primitieve datatypes
  \$scope.addItem = function(obj, property, selected, ResourceId){
    if(selected.value != ''){
      if(obj[property] === null) obj[property] = [];
      obj[property].push(selected.value);
      selected.value = '';
      \$scope.patch(ResourceId);
    }else{
    	console.log('Empty value selected');
    }
  }
  
  //Function to remove item from array of primitieve datatypes
  \$scope.removeItem = function(obj, key, ResourceId){
    obj.splice(key, 1);
    \$scope.patch(ResourceId);
  }
$else$  // The interface does not contain any editable relations
$endif$
$if(containsEditableNonPrim)$  // The interface contains at least 1 editable relation to a non-primitive concept
  // AddObject function to add a new item (val) to a certain property (property) of an object (obj)
  // Also needed by addModal function.
  \$scope.addObject = function(obj, property, selected, ResourceId){
    if(selected.id === undefined || selected.id == ''){
      console.log('selected id is undefined');
    }else{
      if(obj[property] === null) obj[property] = {};
      obj[property][selected.id] = {'id': selected.id};
      selected.id = ''; // reset input field
      \$scope.patch(ResourceId);
    }
  }
  
  // RemoveObject function to remove an item (key) from list (obj).
  \$scope.removeObject = function(obj, key, ResourceId){
    delete obj[key];
    \$scope.patch(ResourceId);
  }
  
  // Typeahead functionality
  \$scope.selected = {}; // an empty object for temporary storing typeahead selections
  \$scope.typeahead = {}; // an empty object for typeahead


  // A property for every editable relation to another concept (i.e. non-primitive datatypes)
$allEditableNonPrims:{editableNonPrim|
  \$scope.typeahead['$editableNonPrim.labelName$'] = Restangular.all('resource/$editableNonPrim.targetConcept$').getList().\$object;}$
$else$  // The interface does not contain editable relations to non-primitive concepts
$endif$
});
