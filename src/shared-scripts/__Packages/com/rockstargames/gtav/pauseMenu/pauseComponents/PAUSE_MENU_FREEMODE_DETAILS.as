class com.rockstargames.gtav.pauseMenu.pauseComponents.PAUSE_MENU_FREEMODE_DETAILS extends com.rockstargames.gtav.pauseMenu.pauseComponents.PauseMenuComponentBase
{
   var CONTENT;
   var myMC;
   var titleFreemode;
   var scrollableContent;
   var model;
   var defaultPlaceholderA;
   var gfxName;
   var depth;
   var menuBlackAlphaColor;
   var imgLdr;
   var dbg;
   var mapCardStyled = false;
   var mapCardFullscreen = false;
   var mapSafeTop = 0;
   var mapSafeBottom = 720;
   var mapCardTitle = "";
   var mapCardImage = false;
   var mapCardStats;
   var mapCardMC;
   var mapCardHeight = 32;
   static var DISPLAY_TYPE_MISSION = 0;
   static var DISPLAY_TYPE_STORE = 1;
   var displayType = com.rockstargames.gtav.pauseMenu.pauseComponents.PAUSE_MENU_FREEMODE_DETAILS.DISPLAY_TYPE_MISSION;
   var isStandalone = false;
   function PAUSE_MENU_FREEMODE_DETAILS()
   {
      super();
      this.mapCardStats = [];
      _global.gfxExtensions = true;
   }
   function INITIALISE(mc)
   {
      if(mc != undefined)
      {
         super.INITIALISE(mc);
         this.isStandalone = true;
         this.setImageLoaderInfo("mp_mission_details_card",4);
      }
      else
      {
         this.CONTENT = this.myMC;
         this.setImageLoaderInfo("PAUSE_MENU_SP_CONTENT",4);
      }
      this.titleFreemode = com.rockstargames.gtav.pauseMenu.pauseMenuItems.singleplayer.PauseMenuFreemodeDetailsTitleItem(this.CONTENT.attachMovie("freemodeTitleItem","freemodeTitleItemMC",1));
      this.titleFreemode._y = this.CONTENT.descBG._y - this.titleFreemode.getHeight();
      this.scrollableContent = this.CONTENT.createEmptyMovieClip("scrollContent",0);
      this.scrollableContent._y = this.CONTENT.descBG._y;
      this.model = new com.rockstargames.gtav.pauseMenu.pauseMenuItems.singleplayer.PauseMenuFreemodeDetailsModel();
      this.model.createView(0,{id:0,x:0,y:0,rowSpacing:2,columnSpacing:0,container:this.scrollableContent,visibleItems:10,linkage:["freemodeDetailsItem"],viewMaskHeight:430,selectstyle:com.rockstargames.ui.components.GUIView.SCROLL_SELECTSTYLE});
      this.CONTENT.verifiedMC._visible = this.CONTENT.verifiedbgMC._visible = false;
      this.CONTENT._visible = false;
      com.rockstargames.ui.utils.Colour.ApplyHudColour(this.CONTENT.descBG,com.rockstargames.ui.utils.HudColour.HUD_COLOUR_PAUSE_BG);
      com.rockstargames.ui.utils.Colour.ApplyHudColour(this.CONTENT.verifiedbgMC,com.rockstargames.ui.utils.HudColour.HUD_COLOUR_WHITE);
      com.rockstargames.ui.utils.Colour.ApplyHudColour(this.CONTENT.imgPlaceholderMC,com.rockstargames.ui.utils.HudColour.HUD_COLOUR_PAUSE_BG);
      this.defaultPlaceholderA = this.CONTENT.imgPlaceholderMC._alpha;
   }
   function setImageLoaderInfo(_gfxName, _depth)
   {
      this.gfxName = _gfxName;
      this.depth = _depth;
   }
   function SET_TITLE(str)
   {
      this.mapCardTitle = arguments[1] == undefined ? "" : String(arguments[1]);
      this.mapCardImage = arguments[3] != undefined && arguments[3] != "" && arguments[4] != undefined && arguments[4] != "";
      this.mapCardStats = arguments[6] == 1 ? [] : [arguments[7],arguments[8],arguments[9],arguments[10]];
      this.titleFreemode.highlightTitle(false);
      com.rockstargames.ui.tweenStar.TweenStarLite.removeTweenOf(this.CONTENT.imgPlaceholderMC);
      this.CONTENT.imgPlaceholderMC._alpha = this.defaultPlaceholderA;
      this.CONTENT.imgPlaceholderMC._visible = true;
      var _loc6_ = arguments[1];
      if(_loc6_ != "")
      {
         this.titleFreemode.__set__data([0,0,0,0,0,0,_loc6_]);
         this.titleFreemode._visible = true;
         this.CONTENT._y = 0;
      }
      else
      {
         this.titleFreemode._visible = false;
         this.CONTENT._y = -27;
      }
      var _loc9_ = arguments[2];
      var _loc7_ = arguments[3];
      var _loc5_ = arguments[4];
      var _loc10_ = 0;
      if(arguments[5] != undefined)
      {
         _loc10_ = arguments[5];
      }
      this.displayType = arguments[6];
      if(_loc6_ == "" || _loc6_ == undefined)
      {
         this.CONTENT.titleTF._visible = false;
         this.CONTENT.verifiedMC._visible = false;
      }
      else
      {
         this.CONTENT.titleTF.text = _loc6_;
         this.CONTENT.titleTF._visible = true;
         if(_loc9_ == 1)
         {
            this.CONTENT.verifiedMC._visible = this.CONTENT.verifiedbgMC._visible = true;
            com.rockstargames.gtav.Multiplayer.ROCKSTAR_VERIFIED(this.CONTENT.verifiedMC).SET_VERIFIED(1);
         }
         else if(_loc9_ == 2)
         {
            this.CONTENT.verifiedMC._visible = this.CONTENT.verifiedbgMC._visible = true;
            com.rockstargames.gtav.Multiplayer.ROCKSTAR_VERIFIED(this.CONTENT.verifiedMC).SET_VERIFIED(2);
         }
         else
         {
            this.CONTENT.verifiedMC._visible = this.CONTENT.verifiedbgMC._visible = false;
         }
      }
      var _loc3_ = this.menuBlackAlphaColor;
      if(_loc7_ != undefined && _loc5_ != undefined && _loc7_ != "" && _loc5_ != "")
      {
         if(this.imgLdr == undefined)
         {
            // attachMovie already applies GenericImageLoader's registered class.
            // JPEXS cannot resolve the external ImageLoaderMC type here and
            // compiles its cast as a class-function call instead of CastOp.
            this.imgLdr = this.CONTENT.imgMC.attachMovie("GenericImageLoader","imgLdr",this.CONTENT.imgMC.getNextHighestDepth());
         }
         var _loc12_ = false;
         if(this.imgLdr.textureDict == _loc7_ && this.imgLdr.textureFilename == _loc5_)
         {
            _loc12_ = true;
         }
         else if(this.imgLdr.isLoaded)
         {
            this.imgLdr.removeTxdRef();
         }
         switch(this.displayType)
         {
            case com.rockstargames.gtav.pauseMenu.pauseComponents.PAUSE_MENU_FREEMODE_DETAILS.DISPLAY_TYPE_STORE:
               this.imgLdr.init(this.gfxName,_loc7_,_loc5_,256,64,16,48);
               if(arguments[7] != undefined && arguments[8] != undefined && arguments[9] != undefined)
               {
                  _loc3_ = new com.rockstargames.ui.utils.HudColour();
                  _loc3_.r = arguments[7];
                  _loc3_.g = arguments[8];
                  _loc3_.b = arguments[9];
               }
               break;
            case com.rockstargames.gtav.pauseMenu.pauseComponents.PAUSE_MENU_FREEMODE_DETAILS.DISPLAY_TYPE_MISSION:
            default:
               this.imgLdr.init(this.gfxName,_loc7_,_loc5_,288,160,0,0);
         }
         var _loc8_ = String(this.imgLdr).split(".");
         var _loc11_ = _loc8_.slice(_loc8_.length - this.depth).join(".");
         if(_loc10_ == 0)
         {
            this.imgLdr.addTxdRef(_loc11_,this.transitionInBitmap,this);
         }
         else
         {
            this.imgLdr.requestTxdRef(_loc11_,_loc12_,this.transitionInBitmap,this);
         }
      }
      if(this.imgLdr != undefined)
      {
         this.imgLdr._visible = false;
      }
      if(this.displayType != com.rockstargames.gtav.pauseMenu.pauseComponents.PAUSE_MENU_FREEMODE_DETAILS.DISPLAY_TYPE_STORE)
      {
         var _loc4_ = !this.CONTENT.verifiedMC._visible ? this.CONTENT.verifiedMC._y + 4.5 : this.CONTENT.verifiedMC._y + 26;
         if(arguments[10])
         {
            this.CONTENT.cmMultTF._y = _loc4_;
            this.CONTENT.cmIconMC._y = this.CONTENT.cmMultTF._y + 14;
            _loc4_ += 30;
            this.CONTENT.cmMultTF.text = arguments[10];
            var _loc0_ = null;
            this.CONTENT.cmIconMC._visible = _loc0_ = true;
            this.CONTENT.cmMultTF._visible = _loc0_;
         }
         else
         {
            this.CONTENT.cmIconMC._visible = _loc0_ = false;
            this.CONTENT.cmMultTF._visible = _loc0_;
         }
         if(arguments[9])
         {
            this.CONTENT.apMultTF._y = _loc4_;
            this.CONTENT.apIconMC._y = this.CONTENT.apMultTF._y + 14;
            _loc4_ += 30;
            this.CONTENT.apMultTF.text = arguments[9];
            this.CONTENT.apIconMC._visible = _loc0_ = true;
            this.CONTENT.apMultTF._visible = _loc0_;
         }
         else
         {
            this.CONTENT.apIconMC._visible = _loc0_ = false;
            this.CONTENT.apMultTF._visible = _loc0_;
         }
         if(arguments[7])
         {
            this.CONTENT.rpMultTF._y = _loc4_;
            this.CONTENT.rpIconMC._y = this.CONTENT.rpMultTF._y + 14;
            _loc4_ += 30;
            this.CONTENT.rpMultTF.text = arguments[7];
            this.CONTENT.rpIconMC._visible = _loc0_ = true;
            this.CONTENT.rpMultTF._visible = _loc0_;
         }
         else
         {
            this.CONTENT.rpIconMC._visible = _loc0_ = false;
            this.CONTENT.rpMultTF._visible = _loc0_;
         }
         if(arguments[8])
         {
            this.CONTENT.cashMultTF._y = _loc4_;
            this.CONTENT.cashIconMC._y = this.CONTENT.cashMultTF._y + 14;
            _loc4_ += 30;
            this.CONTENT.cashMultTF.text = arguments[8];
            this.CONTENT.cashIconMC._visible = _loc0_ = true;
            this.CONTENT.cashMultTF._visible = _loc0_;
         }
         else
         {
            this.CONTENT.cashIconMC._visible = _loc0_ = false;
            this.CONTENT.cashMultTF._visible = _loc0_;
         }
      }
      else
      {
         this.CONTENT.cmIconMC._visible = _loc0_ = false;
         this.CONTENT.cmMultTF._visible = _loc0_;
         this.CONTENT.apIconMC._visible = _loc0_ = false;
         this.CONTENT.apMultTF._visible = _loc0_;
         this.CONTENT.rpIconMC._visible = _loc0_ = false;
         this.CONTENT.rpMultTF._visible = _loc0_;
         this.CONTENT.cashIconMC._visible = _loc0_ = false;
         this.CONTENT.cashMultTF._visible = _loc0_;
      }
      com.rockstargames.ui.utils.Colour.Colourise(this.CONTENT.imgPlaceholderMC,_loc3_.r,_loc3_.g,_loc3_.b,_loc3_.a);
      this.applyMapCardStyle();
   }
   function transitionInBitmap()
   {
      this.imgLdr._alpha = 0;
      this.imgLdr._visible = true;
      com.rockstargames.ui.tweenStar.TweenStarLite.removeTweenOf(this.imgLdr);
      com.rockstargames.ui.tweenStar.TweenStarLite.removeTweenOf(this.CONTENT.imgPlaceholderMC);
      com.rockstargames.ui.tweenStar.TweenStarLite.to(this.imgLdr,0.3,{_alpha:100,ease:com.rockstargames.ui.tweenStar.Ease.QUADRATIC_OUT});
      com.rockstargames.ui.tweenStar.TweenStarLite.to(this.CONTENT.imgPlaceholderMC,0.3,{_alpha:0,ease:com.rockstargames.ui.tweenStar.Ease.QUADRATIC_OUT,onCompleteScope:this,onComplete:this.transitionComplete});
   }
   function transitionComplete()
   {
      this.CONTENT.imgPlaceholderMC._alpha = this.defaultPlaceholderA;
      this.CONTENT.imgPlaceholderMC._visible = false;
      this.applyMapCardStyle();
   }
   function ON_DESTROY()
   {
      if(this.imgLdr.isLoaded == true)
      {
         this.imgLdr.removeTxdRef();
      }
      this.CONTENT._visible = false;
      if(this.imgLdr)
      {
         com.rockstargames.ui.tweenStar.TweenStarLite.removeTweenOf(this.imgLdr);
      }
      com.rockstargames.ui.tweenStar.TweenStarLite.removeTweenOf(this.CONTENT.imgPlaceholderMC);
   }
   function SET_DATA_SLOT_EMPTY(viewIndex, itemIndex)
   {
      super.SET_DATA_SLOT_EMPTY(viewIndex,itemIndex);
      if(this.imgLdr.isLoaded == true)
      {
         this.imgLdr.removeTxdRef();
      }
      this.updateDescBG();
      this.CONTENT._visible = false;
   }
   function DISPLAY_VIEW(viewIndex, itemIndex)
   {
      super.DISPLAY_VIEW(viewIndex,itemIndex);
      this.updateDescBG();
      this.CONTENT._visible = true;
      com.rockstargames.ui.tweenStar.TweenStarLite.removeTweenOf(this.CONTENT);
   }
   function updateDescBG()
   {
      if(this.mapCardStyled)
      {
         this.applyMapCardStyle();
         return;
      }
      switch(this.displayType)
      {
         case com.rockstargames.gtav.pauseMenu.pauseComponents.PAUSE_MENU_FREEMODE_DETAILS.DISPLAY_TYPE_STORE:
            this.CONTENT.descBG._height = this.scrollableContent._height;
            break;
         case com.rockstargames.gtav.pauseMenu.pauseComponents.PAUSE_MENU_FREEMODE_DETAILS.DISPLAY_TYPE_MISSION:
         default:
            var _loc3_ = this.model.getCurrentView().itemList;
            var _loc5_ = _loc3_.length;
            var _loc2_ = com.rockstargames.gtav.pauseMenu.pauseMenuItems.singleplayer.PauseMenuFreemodeDetailsItem(_loc3_[_loc3_.length - 1]);
            var _loc6_ = _loc2_.leftlabelMC.titleTF.textHeight;
            var _loc7_ = 5;
            var _loc4_ = 243;
            if(_loc2_.type == 5)
            {
               _loc4_ = _loc2_._y + _loc2_.leftlabelMC._y + _loc6_ + _loc7_ * 2;
            }
            else
            {
               _loc4_ = 2 + 27 * (_loc5_ - 1) + 25;
            }
            this.CONTENT.descBG._height = _loc4_;
      }
   }
   function SET_FOCUS(isFocused)
   {
      super.SET_FOCUS(isFocused);
      this.titleFreemode.highlightTitle(Boolean(isFocused));
      this.applyMapCardStyle();
   }
   function getKeys()
   {
      if(Key.isDown(38))
      {
         this.SET_INPUT_EVENT(com.rockstargames.ui.game.GamePadConstants.DPADUP);
      }
      else if(Key.isDown(40))
      {
         this.SET_INPUT_EVENT(com.rockstargames.ui.game.GamePadConstants.DPADDOWN);
      }
   }
   function SET_INPUT_EVENT(direction)
   {
      if(direction == com.rockstargames.ui.game.GamePadConstants.DPADUP)
      {
         this.model.prevItem();
      }
      if(direction == com.rockstargames.ui.game.GamePadConstants.DPADDOWN)
      {
         this.model.nextItem();
      }
      this.applyMapCardStyle();
   }
   function SET_MAP_CARD_LAYOUT(fullscreen, safeTop, safeBottom)
   {
      // Only the map page calls this; other shared-component consumers stay native.
      this.mapCardStyled = true;
      this.mapCardFullscreen = fullscreen;
      this.mapSafeTop = safeTop;
      this.mapSafeBottom = safeBottom;
      this.applyMapCardStyle();
   }
   function cardRect(mc, x, y, width, height, color, alpha)
   {
      mc.beginFill(color,alpha);
      mc.moveTo(x,y);
      mc.lineTo(x + width,y);
      mc.lineTo(x + width,y + height);
      mc.lineTo(x,y + height);
      mc.lineTo(x,y);
      mc.endFill();
   }
   function cardText(field, size, color, heading)
   {
      if(field == undefined)
      {
         return;
      }
      var format = field.getTextFormat();
      format.font = heading ? "Figtree" : "$Font2_cond_NOT_GAMERNAME";
      format.size = size;
      format.color = color;
      format.bold = heading;
      format.italic = false;
      field.embedFonts = true;
      field.selectable = false;
      field.setNewTextFormat(format);
      field.setTextFormat(format);
   }
   function fitCardText(field, width)
   {
      if(field == undefined)
      {
         return;
      }
      field.autoSize = false;
      field._width = width;
      var format = field.getTextFormat();
      var label = field.text;
      while(field.textWidth > width - 4 && label.length > 1)
      {
         label = label.substring(0,label.length - 1);
         field.text = label + "...";
         field.setTextFormat(format);
      }
   }
   function applyMapCardStyle()
   {
      if(!this.mapCardStyled || this.CONTENT == undefined || this.model == undefined)
      {
         return;
      }
      if(this.mapCardMC == undefined)
      {
         this.mapCardMC = this.CONTENT.createEmptyMovieClip("mapCardStyle",9000);
         this.mapCardMC.createTextField("titleTF",1,10,2,280,29);
         // Keep GTA's cash artwork above the custom reward backing.
         this.CONTENT.cashIconMC.swapDepths(9001);
      }
      var card = this.mapCardMC;
      card.clear();
      this.cardRect(card,0,0,300,32,16382711,100);
      this.titleFreemode._visible = false;
      this.CONTENT.titleTF._visible = false;
      this.CONTENT.verifiedbgMC._visible = false;
      card.titleTF.text = this.mapCardTitle == "" ? "LOCATION" : this.mapCardTitle;
      card.titleTF.autoSize = false;
      card.titleTF.multiline = false;
      card.titleTF.wordWrap = false;
      this.cardText(card.titleTF,20,1449503,true);
      var title = card.titleTF.text;
      while(card.titleTF.textWidth > 276 && title.length > 1)
      {
         title = title.substring(0,title.length - 1);
         card.titleTF.text = title + "...";
         this.cardText(card.titleTF,20,1449503,true);
      }
      var y = 34;
      this.CONTENT.imgMC._visible = this.mapCardImage;
      this.CONTENT.imgMC._x = 6;
      this.CONTENT.imgMC._y = y;
      var placeholder = this.CONTENT.imgPlaceholderMC;
      placeholder._x = 6;
      placeholder._y = y;
      placeholder._width = 288;
      placeholder._height = 160;
      placeholder._visible = !this.mapCardImage || this.imgLdr == undefined || !this.imgLdr.isLoaded || this.imgLdr._visible != true;
      if(placeholder._visible)
      {
         placeholder._alpha = this.defaultPlaceholderA;
      }
      // Reserve the same photo area while empty, loading, or displaying a texture.
      y += 162;
      if(this.CONTENT.verifiedMC._visible)
      {
         this.CONTENT.verifiedMC._x = 14;
         this.CONTENT.verifiedMC._y = 42;
      }
      var statNames = ["RP","$","AP","CM"];
      var nativeNames = ["rp","cash","ap","cm"];
      var rewardY = 40;
      var i = 0;
      while(i < 4)
      {
         this.CONTENT[nativeNames[i] + "MultTF"]._visible = false;
         this.CONTENT[nativeNames[i] + "IconMC"]._visible = false;
         if(card["stat" + i] == undefined)
         {
            card.createTextField("stat" + i,2 + i,10,0,280,25);
         }
         var field = card["stat" + i];
         var value = this.mapCardStats[i];
         field._visible = value != undefined && value != false && value != "" && value != "nil" && value != "undefined";
         if(field._visible)
         {
            field._x = 146;
            field._y = rewardY;
            field.text = i == 1 ? String(value) : statNames[i] + "  " + value;
            field.autoSize = false;
            this.cardText(field,18,15725555,false);
            var rewardFormat = field.getTextFormat();
            rewardFormat.align = "right";
            field.setTextFormat(rewardFormat);
            this.fitCardText(field,i == 1 ? 114 : 140);
            if(i != 1)
            {
               this.cardRect(card,142,rewardY + 1,148,24,1055260,78);
            }
            if(i == 1)
            {
               var cashIcon = this.CONTENT.cashIconMC;
               cashIcon._visible = true;
               cashIcon._width = cashIcon._height = 24;
               // The native circle's registration point is its center.
               cashIcon._x = 276;
               cashIcon._y = rewardY + 13;
            }
            rewardY += 26;
         }
         i++;
      }
      this.scrollableContent._x = 6;
      this.scrollableContent._y = y;
      var items = this.model.getCurrentView().itemList;
      var rowY = 0;
      i = 0;
      while(i < items.length)
      {
         var row = items[i];
         if(row != undefined && row._visible != false)
         {
            this.cardText(row.itemTextLeft,18,15725555,false);
            this.cardText(row.itemTextRight,18,15725555,false);
            this.cardText(row.labelMC.nameTF,18,15725555,false);
            if(row.type < 2)
            {
               this.fitCardText(row.itemTextLeft,128);
               row.itemTextRight._x = 138;
               this.fitCardText(row.itemTextRight,144);
            }
            else if(row.type == 2)
            {
               this.fitCardText(row.itemTextLeft,112);
               this.fitCardText(row.itemTextRight,Math.max(40,row.itemTextRight._width));
            }
            else if(row.type == 3 || row.type == 4)
            {
               this.fitCardText(row.itemTextLeft,128);
               this.fitCardText(row.type == 3 ? row.labelMC.nameTF : row.itemTextRight,130);
            }
            row._y = rowY;
            var rowHeight = row.type == 5 ? Math.max(30,row.itemTextLeft.textHeight + 12) : 30;
            row.bgMC._height = rowHeight;
            row.bgMC._visible = false;
            row.outlineMC._visible = false;
            this.cardRect(card,0,y + rowY + rowHeight - 1,300,1,8096921,45);
            if(row.type == 4)
            {
               this.cardRect(card,0,y + rowY,300,1,8096921,70);
            }
            rowY += rowHeight;
         }
         i++;
      }
      this.mapCardHeight = y + rowY + 6;
      this.CONTENT.descBG._x = 0;
      this.CONTENT.descBG._y = 32;
      this.CONTENT.descBG._width = 300;
      this.CONTENT.descBG._height = this.mapCardHeight - 32;
      com.rockstargames.ui.utils.Colour.Colourise(this.CONTENT.descBG,20,29,30,90);
      var scale = 0.85;
      this.CONTENT._y = 0;
      if(this.mapCardFullscreen)
      {
         var top = this.mapSafeTop + 68;
         var bottom = this.mapSafeBottom - 44;
         scale = Math.min(0.85,Math.max(1,bottom - top) / this.mapCardHeight);
         var centered = (this.mapSafeTop + this.mapSafeBottom - this.mapCardHeight * scale) / 2;
         this.CONTENT._y = Math.round(Math.max(top,Math.min(centered,bottom - this.mapCardHeight * scale)));
      }
      this.CONTENT._xscale = this.CONTENT._yscale = 100 * scale;
   }
   function TXD_HAS_LOADED(textureDict, success, uniqueID)
   {
      this.dbg("TXD_HAS_LOADED textureDict: " + textureDict + " success: " + success + " uniqueID: " + uniqueID);
      if(success)
      {
         this.imgLdr.displayTxdResponse(textureDict,success);
      }
   }
   function TXD_ALREADY_LOADED(textureDict, uniqueID)
   {
      this.dbg("TXD_ALREADY_LOADED textureDict: " + textureDict + " uniqueID: " + uniqueID);
      this.imgLdr.displayTxdResponse(textureDict,true);
   }
   function ADD_TXD_REF_RESPONSE(textureDict, uniqueID, success)
   {
      this.dbg("ADD_TXD_REF_RESPONSE textureDict: " + textureDict + " uniqueID: " + uniqueID + " success: " + success);
      if(success)
      {
         this.imgLdr.displayTxdResponse(textureDict);
      }
   }
}
