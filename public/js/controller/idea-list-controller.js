angular.module('idea-boardy')
    .controller('IdeaListController', ['$scope', '$http',
    function ($scope, $http) {
        $http.get($scope.section.links.getLink('section').href).success(function (section) {
            $http.get(section.links.getLink('ideas').href).success(function (ideas) {
                $scope.ideas = ideas;
            });
        });
        $scope.$on(ScopeEvent.refresh, function () {
            $http.get($scope.section.links.getLink('ideas').href).success(function (ideas) {
                $scope.ideas = ideas;
            });
        });
    }
]);