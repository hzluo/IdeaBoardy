angular.module('idea-boardy')
  .factory('email', ['$http', ($http) ->
    invite: (recipients, board) ->
      $http.post(board.links.getLink('invitation').href, {to: recipients, board: board})
    share: (recipients, board) ->
      $http.post(board.links.getLink('share').href, {to: recipients, board: board})
  ])