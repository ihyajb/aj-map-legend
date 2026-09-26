class com.rockstargames.gtav.pauseMenu.pauseMenuItems.singleplayer.PauseMenuMapModel extends com.rockstargames.ui.components.GUIModel
{
   var viewList;
   var viewIndex;
   var getCurrentView;
   function PauseMenuMapModel()
   {
      super();
   }
   function createView(_viewIndex, _params)
   {
      var _loc2_ = this.viewList[_viewIndex];
      if(_loc2_ == undefined)
      {
         _loc2_ = new com.rockstargames.gtav.pauseMenu.pauseMenuItems.singleplayer.PauseMenuMapView();
      }
      _loc2_.viewIndex = _viewIndex;
      _loc2_.__set__params(_params);
      this.viewList[_viewIndex] = _loc2_;
   }
   function updateSlot(viewIndex, nativeIndex, data)
   {
      var view = this.getCurrentView(viewIndex);
      view.addItem(nativeIndex,data);
      view.renderSelection(view.__get__index());
   }
   function addSlot(viewIndex, nativeIndex, data)
   {
      this.updateSlot(viewIndex,nativeIndex,data);
   }
   function removeDataFromSlot(_viewIndex, _slotIndex)
   {
      var _loc2_ = this.viewList[_viewIndex];
      _loc2_.destroy();
      _loc2_.topEdge = 0;
      this.viewIndex = 0;
      var _loc3_ = com.rockstargames.gtav.pauseMenu.pauseMenuItems.singleplayer.PauseMenuMapView(this.getCurrentView());
   }
}
