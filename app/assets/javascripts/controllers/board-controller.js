angular.module('idea-boardy')
    .controller('BoardController', ['$scope', '$http', '$location', '$q', 'params', 'dialog', 'color', 'events', 'autoUpdater',
    function ($scope, $http, $location, $q, params, dialog, color, events, autoUpdater) {
        var tagsInBoard = [],
            concepts = [],
            deleteBoardDialog = dialog('deleteBoardDialog'),
            createSectionDialog = dialog('createSectionDialog'),
            createTagDialog = dialog('createTagDialog'),
            editTagDialog = dialog('editTagDialog'),
            deleteTagDialog = dialog('deleteTagDialog'),
            deleteIdeaDialog = dialog('deleteIdeaDialog'),
            deleteSectionDialog = dialog('deleteSectionDialog'),
            editConceptDialog = dialog('editConceptDialog'),
            invitationDialog = dialog('invitationDialog');
        autoUpdater.clear();
        $http.get(params('uri'), {params:{embed:"tags,concepts"}})
            .success(function (board) {
                enhanceBoard(board);
                $scope.board = board;
                tagsInBoard = board.tags;
                _.each(tagsInBoard, enhanceTag);
                concepts = board.concepts;
                _.each(concepts, enhanceConcept);
                refreshSections();
                autoUpdater.register($scope.board.selfLink.href, refreshTags);
            });

        $scope.showDeleteBoardDialog = function () {
            deleteBoardDialog.open({boardToDelete:$scope.board});
        };
        $scope.showCreateSectionDialog = function () {
            createSectionDialog.open({board:$scope.board, sectionToCreate:{color:color(0)}});
        };
        $scope.showCreateTagDialog = function ($event) {
            createTagDialog.open({board:$scope.board, tagToCreate:{}, $event:$event});
        };
        $scope.showEditTagDialog = function (tag, $event) {
            editTagDialog.open({board:$scope.board, tagToEdit:_.clone(tag), $event:$event});
        };
        $scope.showInvitationDialog = function () {
            invitationDialog.open({boardToInvite:$scope.board, recipients:[{}]});
        };
        $scope.showDeleteTagDialog = function (tag) {
            deleteTagDialog.open({board:$scope.board, tagToDelete:tag});
        };
        $scope.showDeleteIdeaDialog = function (idea) {
            deleteIdeaDialog.open({ideaToDelete:idea});
        };
        $scope.showDeleteSectionDialog = function (section) {
            deleteSectionDialog.open({sectionToDelete:section});
        };
        $scope.showEditConceptDialog = function (concept, tag, $event) {
            var tagNamesInConcept = _.map(concept.tags, function(tag) {return tag.name;}),
                tagNames = !!tag ? tagNamesInConcept.concat((tag||{}).name) : tagNamesInConcept,
                aConcept = _.clone(concept);
            editConceptDialog.open({
                concept: aConcept,
                tagNames: tagNames,
                allTagNames: $scope.getAllTagNames(),
                $event: $event
            });
        };
        $scope.goToReport = function (board) {
            $location.path('report').search({uri:board.selfLink.href});
        };
        $scope.getTags = function () {
            return tagsInBoard;
        };
        $scope.getTagsInConcept = function () {
            var tagsInConcept = _.filter($scope.getTags(), function (tag) {
                    return !!tag.links.getLink('concept').href;
                }),
                tagsGroupedByConcept = _.groupBy(tagsInConcept, function (tag) {
                    return tag.links.getLink('concept').href;
                }),
                conceptWithTags = _.map(_.keys(tagsGroupedByConcept), function (conceptUri) {
                    var concept = _.find(concepts, function (c) {
                        return conceptUri === c.links.getLink('self').href
                    });
                    return _.extend(concept, {
                        tags:tagsGroupedByConcept[conceptUri]
                    });
                });
            return _.sortBy(conceptWithTags, function (concept) { return concept.name; });
        };
        $scope.getTagsNotInConcept = function () {
            return _.filter($scope.getTags(), function(tag) {return !tag.links.getLink('concept').href;});
        };
        $scope.getAllTagNames = function() {
            return _.map($scope.getTags(), function(tag) {return tag.name});
        };

        $scope.$on(events.editSection, function (event, targetSection) {
            if (event.stopPropagation) event.stopPropagation();
            if (event.targetScope == $scope) return;
            $scope.$broadcast(events.editSection, targetSection);
        });

        $scope.$on(events.sectionEditingFinished, function (event, targetSection) {
            if (event.stopPropagation) event.stopPropagation();
            if (event.targetScope == $scope) return;
            $scope.$broadcast(events.sectionEditingFinished, targetSection);
        });

        $scope.$on(events.sectionDeleted, function (event, index) {
            if (event.stopPropagation) event.stopPropagation();
            clearRegisteredUpdaters();
            $scope.sections.splice(index, 1);
            refreshSections();
        });

        function clearRegisteredUpdaters() {
            _.each($scope.sections, function (section) {
                autoUpdater.unregister(section.links.getLink('section').href);
            });
        }

        $scope.$on(events.tagCreated, function (event) {
            if (event.stopPropagation) event.stopPropagation();
            refreshTags();
        });

        function enhanceBoard(rawBoard) {
            angular.extend(rawBoard, {
                selfLink:rawBoard.links.getLink('self'),
                invitationLink:rawBoard.links.getLink('invitation'),
                tagsLink:rawBoard.links.getLink('tags'),
                sectionsLink:rawBoard.links.getLink('sections'),
                mode:"view",
                selectedSectionName:"",
                edit:function () {
                    this.mode = 'edit'
                },
                delete:function () {
                    $http.delete(this.links.getLink('self').href).success(function () {
                        $location.path("").search({});
                    });
                },
                createSection:function (sectionToCreate) {
                    $http.post(this.sectionsLink.href, sectionToCreate).success(refreshSections);
                },
                cancel:function () {
                    this.mode = 'view'
                },
                isSectionVisible:function (section) {
                    return !this.selectedSectionName || section.name == this.selectedSectionName;
                },
                sectionClass:function () {
                    return !this.selectedSectionName ? 'narrow-rectangle' : 'wide-rectangle'
                },
                createTag:function (tag) {
                    $http.post($scope.board.tagsLink.href, tag).success(refreshTags);
                },
                updateTag:function (tag) {
                    $http.put(tag.links.getLink('self').href, tag).success(refreshTags);
                },
                deleteTag:function (tag) {
                    $http.delete(tag.links.getLink('self').href).success(refreshTags);
                }
            });
        }

        function enhanceTag(rawTag) {
            angular.extend(rawTag, {
                $$hashKey: function() { return this.id + '_' + this.name; }
            });
        }

        function enhanceConcept(rawConcept) {
            angular.extend(rawConcept, {
                $$hashKey: function() { return this.id + '_' + this.name; },
                update: function(tagNames) {
                    var updateConceptPromise = $http.put(this.links.getLink('self').href, {name: this.name}),
                        tagIds = _.map(tagNames, function(tagName) {return _.find(tagsInBoard, function(tag) {return tag.name===tagName}).id;}),
                        updateTagsPromise = $http.put(this.links.getLink('tags').href, {tags: tagIds});
                    $q.all([updateConceptPromise, updateTagsPromise]).then(refreshTags);
                }
            });
        }

        function refreshTags() {
            $http.get($scope.board.selfLink.href, {params:{embed:'tags,concepts'}}).success(function (board) {
                tagsInBoard = board.tags;
                _.each(tagsInBoard, enhanceTag);
                concepts = board.concepts;
                _.each(concepts, enhanceConcept);
            });
        }

        function refreshSections() {
            $http.get($scope.board.sectionsLink.href).success(function (sections) {
                $scope.sections = sections;
            });
        }
    }
]);

