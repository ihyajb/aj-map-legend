class com.rockstargames.gtav.pauseMenu.pauseComponents.PAUSE_MENU_MAP extends com.rockstargames.gtav.pauseMenu.pauseComponents.PauseMenuComponentBase
{
   var dbgID;
   var CONTENT;
   var details;
   var zoom;
   var location;
   var model;
   var scrollBase;
   var viewableItems = 16;
   function PAUSE_MENU_MAP()
   {
      super();
      this.dbgID = "PAUSE_MENU_MAP";
   }
   function INITIALISE(mc)
   {
      if(mc != undefined)
      {
         super.INITIALISE(mc);
      }
      else
      {
         this.CONTENT = this;
      }
      this.details = this.CONTENT.mapDetailsMC;
      this.zoom = this.details.zoomMC;
      this.location = this.details.locationMC;
      com.rockstargames.ui.utils.Colour.ApplyHudColour(this.zoom,com.rockstargames.ui.utils.HudColour.HUD_COLOUR_WHITE);
      com.rockstargames.ui.utils.Colour.ApplyHudColour(this.location.bgMC,com.rockstargames.ui.utils.HudColour.HUD_COLOUR_PAUSE_BG);
      com.rockstargames.ui.utils.Colour.ApplyHudColour(this.location.labelMC,com.rockstargames.ui.utils.HudColour.HUD_COLOUR_WHITE);
      this.model = new com.rockstargames.gtav.pauseMenu.pauseMenuItems.singleplayer.PauseMenuMapModel();
      this.model.createView(0,{id:0,x:868,y:0,rowSpacing:0,columnSpacing:0,container:this.CONTENT,linkage:["mapLegendItem"],visibleItems:this.viewableItems,selectstyle:com.rockstargames.ui.components.GUIView.SCROLL_SELECTSTYLE});
      this.SET_TITLE();
      this.updateScroll();
   }
   function SET_TITLE(str)
   {
      // The game still supplies the live area name and distance callbacks.
      this.zoom._visible = false;
      this.location.bgMC._visible = false;
      this.location._x = this.location._y = 0;
      this.location.labelMC._x = this.location.labelMC._y = 0;
      if(str != undefined && str != "")
      {
         var title = this.location.labelMC.locationTF;
         // Use the same verified font as the legend. The fontmap alone does not
         // guarantee a face (or its bold/italic variant) has loaded glyphs.
         var format = new TextFormat("$Font2_cond_NOT_GAMERNAME",32,16777215);
         format.align = "left";
         format.bold = false;
         format.italic = false;
         title._x = title._y = 0;
         title._width = 760;
         title._height = 52;
         title.autoSize = "left";
         title.multiline = false;
         title.wordWrap = false;
         title.selectable = false;
         title.embedFonts = true;
         title.setNewTextFormat(format);
         title.text = str.toUpperCase();
         title.setTextFormat(format);
         // A small horizontal overdraw gives the available glyphs extra weight.
         // Reuse one field, so area updates never accumulate display objects.
         var label = this.location.labelMC;
         if(label.weightTF == undefined)
         {
            label.createTextField("weightTF",100,0.75,0,760,52);
         }
         var weight = label.weightTF;
         weight._x = title._x + 0.75;
         weight._y = title._y;
         weight.autoSize = "left";
         weight.multiline = false;
         weight.wordWrap = false;
         weight.selectable = false;
         weight.embedFonts = true;
         weight.setNewTextFormat(format);
         weight.text = title.text;
         weight.setTextFormat(format);
         this.location._visible = true;
      }
      else
      {
         this.location._visible = false;
      }
      this.updateScroll();
   }
   function SET_DESCRIPTION()
   {
      this.zoom._visible = false;
      this.updateScroll();
   }
   function SET_HIGHLIGHT(i)
   {
      var _loc2_ = com.rockstargames.gtav.pauseMenu.pauseMenuItems.singleplayer.PauseMenuMapView(this.model.getCurrentView());
      _loc2_.__set__index(i);
      this.updateScroll();
   }
   function DISPLAY_VIEW(viewIndex, itemIndex)
   {
      if(itemIndex == undefined)
      {
         itemIndex = 0;
      }
      this.model.displayView(viewIndex,itemIndex);
      this.model.getCurrentView().jumpTo(itemIndex);
      this.SEND_COLUMN_PARAMS();
      this.updateScroll();
   }
   function SET_INPUT_EVENT(input)
   {
      var _loc2_ = this.model.getCurrentView().itemList[this.model.getCurrentView().highlightedItem];
      switch(input)
      {
         case com.rockstargames.ui.game.GamePadConstants.DPADUP:
            this.model.getCurrentView().moveSelection(-1);
            break;
         case com.rockstargames.ui.game.GamePadConstants.DPADDOWN:
            this.model.getCurrentView().moveSelection(1);
            break;
         case com.rockstargames.ui.game.GamePadConstants.DPADRIGHT:
            _loc2_.stepVal(1);
            break;
         case com.rockstargames.ui.game.GamePadConstants.DPADLEFT:
            _loc2_.stepVal(-1);
            break;
         case com.rockstargames.ui.game.GamePadConstants.FRONTEND_CONTEXT_BUTTON:
            _loc2_.__set__showBlips(!_loc2_.__get__showBlips());
      }
      this.updateScroll();
   }
   function SET_DATA_SLOT(sup)
   {
      super.SET_DATA_SLOT.apply(super,arguments);
      this.updateScroll();
   }
   function INIT_SCROLL_BAR(visible, columns, scrollType, arrowPosition, override, xColOffset)
   {
      super.INIT_SCROLL_BAR.apply(super,arguments);
      this.updateScroll();
   }
   function SET_SCROLL_BAR(currentPosition, maxPosition, maxVisible, caption)
   {
      super.SET_SCROLL_BAR.apply(super,arguments);
      this.updateScroll();
   }
   function updateScroll()
   {
      // The grouped view draws its own position indicator in visual order.
      if(this.scrollBase != undefined)
      {
         this.scrollBase.forceInvisible = true;
         this.scrollBase._visible = false;
      }
      var view = this.model.getCurrentView();
      if(view.orderDirty && view.displayed)
      {
         view.renderSelection(view.__get__index());
      }
   }
}
