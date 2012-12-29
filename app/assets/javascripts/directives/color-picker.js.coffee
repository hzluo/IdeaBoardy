angular.module('idea-boardy')
  .directive 'colorPicker', [() ->
    restrict: 'E'
    templateUrl: 'assets/color-picker.html'
    replace: true
    controller: ['$scope', '$parse', 'color'
      ($scope, $parse, color) ->
        modelExpr = null
        paletteVisible = false
        useCompactMode = false
        @setModelExpr = (expr) -> modelExpr = expr
        @setCompactMode = (compactMode) -> useCompactMode = compactMode
        $scope.pickColor = (index) -> ($parse(modelExpr)($scope)).color = color(index)
        $scope.mark = (index) ->
          model = $parse(modelExpr)($scope)
          if model? and model.color is color(index) then "✓" else ""
        $scope.getColorIndex = () ->
          color(($parse(modelExpr)($scope))?.color)
        $scope.isPaletteVisible = () -> not useCompactMode or paletteVisible
        $scope.showPalette = () -> paletteVisible = true
        $scope.hidePalette = () -> paletteVisible = false
    ]
    require: 'colorPicker'
    link: (scope, element, attrs, ctrl) ->
      ctrl.setModelExpr(attrs.for)
      ctrl.setCompactMode(attrs.compact?)
  ]