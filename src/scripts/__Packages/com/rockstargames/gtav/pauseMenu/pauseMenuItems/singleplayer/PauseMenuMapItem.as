class com.rockstargames.gtav.pauseMenu.pauseMenuItems.singleplayer.PauseMenuMapItem extends com.rockstargames.gtav.pauseMenu.pauseMenuItems.PauseMenuBaseItem
{
   var selectedValue;
   var valueIndicatorMC;
   var labelMC;
   var valueTF;
   var lMC;
   var rMC;
   var newIconMC;
   var valuesLength;
   var __get__data;
   var initialIndex;
   var itemTextLeft;
   var _highlighted;
   var iconID;
   var iconMC;
   var attachMovie;
   var getNextHighestDepth;
   var _data;
   var bgMC;
   var bMC;
   var _x;
   var storeFunc;
   var storeScope;
   var index;
   var __get__uniqueID;
   var __get__columnID;
   var _xmouse;
   var rowRuleMC;
   var newBadgeMC;
   var createEmptyMovieClip;
   var _showBlips = true;
   var showBlipIndex = 12;
   var initalValueIndex = 4;
   function PauseMenuMapItem()
   {
      super();
      this.selectedValue = 0;
      this.valueIndicatorMC = this.labelMC.valueIndicatorMC;
      this.valueIndicatorMC._visible = false;
      this.valueTF = this.valueIndicatorMC.valueTF;
      this.lMC = this.valueIndicatorMC.lMC;
      this.rMC = this.valueIndicatorMC.rMC;
      this.valueTF.autoSize = "left";
      com.rockstargames.ui.utils.Colour.ApplyHudColour(this.newIconMC,com.rockstargames.ui.utils.HudColour.HUD_COLOUR_SOCIAL_CLUB);
   }
   function set data(_d)
   {
      // Preserve Rockstar's explicit accessors; this.data has an empty property getter.
      super.__set__data(_d);
      this.valuesLength = this.__get__data()[5] <= 1 ? 1 : this.__get__data()[5];
      this._showBlips = this.__get__data()[6] == false ? false : true;
      this.selectedValue = this.initialIndex;
      this.updateDisplay();
   }
   function displayLabel()
   {
      if(this.iconID == "radar_centre")
      {
         return "You";
      }
      var label = String(this.__get__data()[0]).split("<C>").join("").split("</C>").join("");
      if(this.storeScope != undefined)
      {
         label = this.storeScope.parseLabel(label).label;
      }
      return label;
   }
   function updateDisplay()
   {
      var rowData = this.__get__data();
      if(rowData == undefined || rowData[0] == undefined)
      {
         return;
      }
      this.iconID = rowData[4];
      this._x = -300;
      this.bgMC._width = this.bMC._width = 300;
      this.bgMC._height = this.bMC._height = 32;
      this.labelMC._x = 42;
      this.labelMC._y = 3;
      this.newIconMC._visible = false;
      this.itemTextLeft.autoSize = "left";
      this.itemTextLeft.multiline = false;
      this.itemTextLeft.wordWrap = false;
      this.itemTextLeft.text = this.displayLabel();
      var labelFormat = this.itemTextLeft.getTextFormat();
      labelFormat.font = "$Font2_cond_NOT_GAMERNAME";
      labelFormat.bold = false;
      labelFormat.italic = false;
      this.itemTextLeft.embedFonts = true;
      labelFormat.size = 18;
      this.itemTextLeft.setNewTextFormat(labelFormat);
      this.itemTextLeft.setTextFormat(labelFormat);
      var hasCounter = this.valuesLength > 1 && this._showBlips;
      this.valueIndicatorMC._visible = hasCounter;
      if(hasCounter)
      {
         this.valueTF.text = this.selectedValue + 1 + "/" + this.valuesLength;
         var counterFormat = this.valueTF.getTextFormat();
         counterFormat.font = "$Font2_cond_NOT_GAMERNAME";
         counterFormat.bold = false;
         counterFormat.italic = false;
         this.valueTF.embedFonts = true;
         counterFormat.size = 18;
         this.valueTF.setNewTextFormat(counterFormat);
         this.valueTF.setTextFormat(counterFormat);
         this.valueTF._x = 12;
         this.valueTF._y = 2;
         this.lMC._x = 2;
         this.rMC._x = Math.round(this.valueTF._x + this.valueTF._width) + 8;
         this.lMC._y = this.rMC._y = 14;
         this.valueIndicatorMC._x = 300 - 42 - this.valueIndicatorMC._width - 12;
      }
      var textWidth = hasCounter ? Math.max(40,this.valueIndicatorMC._x - 10) : 240;
      var isNew = this.storeScope != undefined && this.storeScope.parseLabel(rowData[0]).isNew;
      if(this.newBadgeMC != undefined)
      {
         this.newBadgeMC._visible = isNew;
      }
      if(isNew)
      {
         if(this.newBadgeMC == undefined)
         {
            this.newBadgeMC = this.createEmptyMovieClip("newBadgeMC",9001);
            this.newBadgeMC.beginFill(16107612,100);
            this.newBadgeMC.moveTo(0,0);
            this.newBadgeMC.lineTo(30,0);
            this.newBadgeMC.lineTo(30,16);
            this.newBadgeMC.lineTo(0,16);
            this.newBadgeMC.endFill();
            this.newBadgeMC.createTextField("badgeTF",1,0,-1,30,20);
            var badgeText = this.newBadgeMC.badgeTF;
            badgeText.text = "NEW";
            badgeText.selectable = false;
            badgeText.embedFonts = true;
            var badgeFormat = new TextFormat("$Font2_cond_NOT_GAMERNAME",12,1449503);
            badgeFormat.align = "center";
            badgeFormat.bold = false;
            badgeFormat.italic = false;
            badgeText.setNewTextFormat(badgeFormat);
            badgeText.setTextFormat(badgeFormat);
         }
         this.newBadgeMC._visible = true;
         this.newBadgeMC._x = hasCounter ? this.labelMC._x + this.valueIndicatorMC._x - 36 : 258;
         this.newBadgeMC._y = 8;
         textWidth = Math.max(40,this.newBadgeMC._x - this.labelMC._x - 6);
      }
      var fullLabel = this.itemTextLeft.text;
      while(this.itemTextLeft.textWidth > textWidth && labelFormat.size > 16)
      {
         labelFormat.size -= 1;
         this.itemTextLeft.setTextFormat(labelFormat);
      }
      while(this.itemTextLeft.textWidth > textWidth && fullLabel.length > 1)
      {
         fullLabel = fullLabel.substring(0,fullLabel.length - 1);
         this.itemTextLeft.text = fullLabel + "...";
         this.itemTextLeft.setTextFormat(labelFormat);
      }
      if(this.iconID != undefined)
      {
         var linkage = this._showBlips ? this.iconID : "MapLegendItemCross";
         var instance = this._showBlips ? this.iconID : "crossMC";
         if(this.iconMC._name != instance)
         {
            this.iconMC.removeMovieClip();
            this.iconMC = this.attachMovie(linkage,instance,this.getNextHighestDepth());
         }
         this.iconMC._x = 20;
         this.iconMC._y = 16;
         this.iconMC._xscale = this.iconMC._yscale = 110;
         if(this._showBlips)
         {
            com.rockstargames.ui.utils.Colour.Colourise(this.iconMC,rowData[1],rowData[2],rowData[3]);
         }
         else
         {
            com.rockstargames.ui.utils.Colour.Colourise(this.iconMC,135,146,148,100);
         }
      }
      else
      {
         this.iconMC.removeMovieClip();
      }
      if(this._highlighted)
      {
         com.rockstargames.ui.utils.Colour.Colourise(this.bgMC,249,250,247,100);
         com.rockstargames.ui.utils.Colour.Colourise(this.labelMC,22,30,31,100);
      }
      else
      {
         com.rockstargames.ui.utils.Colour.Colourise(this.bgMC,20,29,30,84);
         var textColor = this._showBlips ? 245 : 145;
         com.rockstargames.ui.utils.Colour.Colourise(this.labelMC,textColor,textColor,textColor,100);
      }
      if(this.rowRuleMC == undefined)
      {
         this.rowRuleMC = this.createEmptyMovieClip("rowRuleMC",9000);
      }
      this.rowRuleMC.clear();
      this.rowRuleMC.beginFill(8096921,45);
      this.rowRuleMC.moveTo(0,31);
      this.rowRuleMC.lineTo(300,31);
      this.rowRuleMC.lineTo(300,32);
      this.rowRuleMC.lineTo(0,32);
      this.rowRuleMC.endFill();
      var accent = this._highlighted ? 4810415 : (rowData[1] << 16 | rowData[2] << 8 | rowData[3]);
      this.rowRuleMC.beginFill(accent,100);
      this.rowRuleMC.moveTo(0,0);
      this.rowRuleMC.lineTo(2,0);
      this.rowRuleMC.lineTo(2,32);
      this.rowRuleMC.lineTo(0,32);
      this.rowRuleMC.endFill();
   }
   function initStoreMethod(func, scope)
   {
      this.storeFunc = func;
      this.storeScope = scope;
   }
   function stepVal(dir)
   {
      var _loc2_ = this.selectedValue + dir;
      this.selectedValue = _loc2_ < this.valuesLength ? (this.selectedValue + dir >= 0 ? _loc2_ : _loc2_ + this.valuesLength) : _loc2_ - this.valuesLength;
      if(this.valuesLength > 1)
      {
         this.storeFunc.apply(this.storeScope,[this.index,this.initalValueIndex,this.selectedValue]);
         com.rockstargames.ui.game.GameInterface.call("SET_MAP_LOCATION",com.rockstargames.ui.game.GameInterface.PAUSE_TYPE,this.__get__uniqueID(),this.selectedValue);
      }
      this.updateDisplay();
   }
   function set highlighted(value)
   {
      if(this._highlighted != value)
      {
         this._highlighted = value;
         this.updateDisplay();
      }
   }
   function get highlighted()
   {
      return this._highlighted;
   }
   function set showBlips(value)
   {
      if(this.iconID == "radar_centre" || this.iconID == "radar_waypoint")
      {
         return;
      }
      var _loc2_ = value == this._showBlips ? false : true;
      this._showBlips = value;
      if(_loc2_)
      {
         this.storeFunc.apply(this.storeScope,[this.index,this.showBlipIndex,this._showBlips]);
         com.rockstargames.ui.game.GameInterface.call("SET_MAP_SHOW_BLIPS",com.rockstargames.ui.game.GameInterface.PAUSE_TYPE,this.__get__uniqueID(),this._showBlips);
      }
      this.updateDisplay();
   }
   function get showBlips()
   {
      return this._showBlips;
   }
   function mPress()
   {
      if(!this.__get__highlighted())
      {
         _level0.TIMELINE.M_PRESS_EVENT(this.index,this.__get__columnID(),false);
      }
      else if(this.valuesLength > 1 && this._xmouse >= this.labelMC._x + this.valueIndicatorMC._x)
      {
         var midpoint = this.labelMC._x + this.valueIndicatorMC._x + (this.lMC._x + this.rMC._x) / 2;
         this.stepVal(this._xmouse < midpoint ? -1 : 1);
      }
   }
}
