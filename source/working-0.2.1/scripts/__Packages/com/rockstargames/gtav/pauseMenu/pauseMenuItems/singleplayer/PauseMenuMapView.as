class com.rockstargames.gtav.pauseMenu.pauseMenuItems.singleplayer.PauseMenuMapView extends com.rockstargames.gtav.pauseMenu.pauseMenuItems.PauseMenuViewBase
{
   var viewContainer;
   var itemList;
   var dataList;
   var _index;
   var topEdge;
   var highlightedItem;
   var visibleItems;
   var maxVisibleItems;
   var order;
   var positions;
   var headings;
   var panelMC;
   var orderDirty = true;
   var displayed = false;
   var listHeight = 512;
   var groupNames;
   function PauseMenuMapView()
   {
      super();
      this.order = [];
      this.positions = [];
      this.headings = [];
      this.groupNames = ["","GOVERNMENT","JOBS","VEHICLES","SHOPS & SERVICES","ACTIVITIES","PROPERTIES","OTHER"];
   }
   function containsAny(label, words)
   {
      var i = 0;
      while(i < words.length)
      {
         if(label.indexOf(words[i]) >= 0)
         {
            return true;
         }
         i++;
      }
      return false;
   }
   function categoryFor(data)
   {
      if(data[10] == "radar_centre" || data[10] == "radar_waypoint")
      {
         return 0;
      }
      var label = String(data[6]).toLowerCase();
      if(this.containsAny(label,["police","sheriff","hospital","medical","ambulance","prison","jail","court","city hall","city services","government","dmv","ranger","fire station"]))
      {
         return 1;
      }
      if(this.containsAny(label,["garages:","customs","mechanic","impound","car wash","carwash","dealership","vehicle shop","vehicle sales","car rental","air shop"]))
      {
         return 3;
      }
      if(this.containsAny(label,["garbage","recycl","panning","mining","quarry","lumber","butcher","farm","vineyard","trucker","trucking","shipping","delivery","postal","courier","taxi","downtown cab","bus depot","foundry"]))
      {
         return 2;
      }
      if(this.containsAny(label,["bank","atm","ammunation","ammu-nation","gun shop","barber","clothing","tattoo","store","shop","market","pawn","restaurant","cafe","diner","burgershot"]))
      {
         return 4;
      }
      if(this.containsAny(label,["diving","fishing","hunting","crafting","golf","casino","race","racing","gym","bowling","arcade","tennis","cinema","beach"]))
      {
         return 5;
      }
      if(this.containsAny(label,["garage","depot","parking","airport","helipad","hangar","hanger","dock"]))
      {
         return 3;
      }
      if(this.containsAny(label,["apartment","property","properties","house","housing","motel","hotel","plaza","real estate"]))
      {
         return 6;
      }
      return 7;
   }
   function addItem(i, data)
   {
      super.addItem(i,data);
      this.orderDirty = true;
   }
   function rebuildOrder()
   {
      if(!this.orderDirty)
      {
         return;
      }
      this.order = [];
      this.positions = [];
      var i = 0;
      while(i < this.dataList.length)
      {
         var data = this.dataList[i];
         if(data != undefined && data[6] != undefined)
         {
            this.order.push({nativeIndex:i,group:this.categoryFor(data),label:String(data[6]).toLowerCase(),player:data[10] == "radar_centre"});
         }
         i++;
      }
      this.order.sort(function(a, b)
      {
         if(a.group != b.group)
         {
            return a.group - b.group;
         }
         if(a.player != b.player)
         {
            return a.player ? -1 : 1;
         }
         if(a.label != b.label)
         {
            return a.label < b.label ? -1 : 1;
         }
         return a.nativeIndex - b.nativeIndex;
      });
      var position = 0;
      while(position < this.order.length)
      {
         this.positions[this.order[position].nativeIndex] = position;
         position++;
      }
      this.orderDirty = false;
   }
   function drawRect(mc, x, y, width, height, color, alpha)
   {
      mc.beginFill(color,alpha);
      mc.moveTo(x,y);
      mc.lineTo(x + width,y);
      mc.lineTo(x + width,y + height);
      mc.lineTo(x,y + height);
      mc.lineTo(x,y);
      mc.endFill();
   }
   function setText(mc, name, depth, label, x, y, width, height, size, color)
   {
      if(mc[name] == undefined)
      {
         mc.createTextField(name,depth,x,y,width,height);
      }
      var field = mc[name];
      field.text = label;
      field.selectable = false;
      field.embedFonts = true;
      field.autoSize = false;
      var format = new TextFormat("$Font2_cond_NOT_GAMERNAME",size,color);
      field.setNewTextFormat(format);
      field.setTextFormat(format);
   }
   function ensurePanel()
   {
      if(this.panelMC == undefined)
      {
         this.panelMC = this.viewContainer.createEmptyMovieClip("locationsPanel",0);
         this.panelMC._x = -300;
         this.panelMC.createEmptyMovieClip("scrollTrack",1);
         this.setText(this.panelMC,"titleTF",2,"LOCATIONS",10,3,280,29,20,1448991);
         this.setText(this.panelMC,"positionTF",3,"",10,548,278,22,16,15725555);
      }
      this.panelMC.clear();
      this.drawRect(this.panelMC,0,0,300,32,16382711,100);
      this.drawRect(this.panelMC,0,34,300,536,1055260,60);
      var i = 0;
      while(i < 16)
      {
         if(this.itemList[i] == undefined)
         {
            var item = this.viewContainer.attachMovie("mapLegendItem","groupedMapItem" + i,10 + i);
            item.initStoreMethod(this.storeDataChange,this);
            this.itemList[i] = item;
         }
         if(this.headings[i] == undefined)
         {
            var heading = this.viewContainer.createEmptyMovieClip("categoryHeading" + i,100 + i);
            heading._x = -300;
            this.drawRect(heading,0,0,300,24,922133,94);
            this.setText(heading,"titleTF",1,"",8,2,280,22,16,15725555);
            this.headings[i] = heading;
         }
         i++;
      }
      this.visibleItems = this.maxVisibleItems = 16;
   }
   function endPosition(start)
   {
      var y = 0;
      var previousGroup = -1;
      var position = start;
      while(position < this.order.length)
      {
         var group = this.order[position].group;
         var headingHeight = group != 0 && group != previousGroup ? 24 : 0;
         if(y + headingHeight + 32 > this.listHeight)
         {
            break;
         }
         y += headingHeight + 32;
         previousGroup = group;
         position++;
      }
      return position;
   }
   function renderSelection(nativeIndex)
   {
      if(!this.displayed)
      {
         return;
      }
      this.rebuildOrder();
      this.ensurePanel();
      var i = 0;
      while(i < 16)
      {
         this.itemList[i]._visible = false;
         this.headings[i]._visible = false;
         i++;
      }
      if(this.order.length == 0)
      {
         this.panelMC.positionTF.text = "No locations";
         this.panelMC.scrollTrack.clear();
         this.highlightedItem = -1;
         return;
      }
      var selectedPosition = this.positions[nativeIndex];
      if(selectedPosition == undefined)
      {
         selectedPosition = 0;
         nativeIndex = this.order[0].nativeIndex;
      }
      this._index = nativeIndex;
      this.topEdge = Math.max(0,Math.min(this.topEdge,selectedPosition));
      while(selectedPosition >= this.endPosition(this.topEdge))
      {
         this.topEdge++;
      }
      var end = this.endPosition(this.topEdge);
      var y = 34;
      var previousGroup = -1;
      var slot = 0;
      var position = this.topEdge;
      while(position < end)
      {
         var entry = this.order[position];
         if(entry.group != 0 && entry.group != previousGroup)
         {
            var heading = this.headings[slot];
            heading._visible = true;
            heading._y = y;
            heading.titleTF.text = this.groupNames[entry.group];
            y += 24;
         }
         var item = this.itemList[slot];
         item._highlighted = entry.nativeIndex == nativeIndex;
         item.__set__data(this.dataList[entry.nativeIndex]);
         item._y = y;
         item._visible = true;
         if(item._highlighted)
         {
            this.highlightedItem = slot;
         }
         previousGroup = entry.group;
         y += 32;
         slot++;
         position++;
      }
      this.panelMC.positionTF.text = selectedPosition + 1 + " / " + this.order.length;
      var track = this.panelMC.scrollTrack;
      track.clear();
      if(end - this.topEdge < this.order.length)
      {
         var thumbHeight = Math.max(24,this.listHeight * (end - this.topEdge) / this.order.length);
         var thumbY = 34 + (this.listHeight - thumbHeight) * this.topEdge / Math.max(1,this.order.length - (end - this.topEdge));
         this.drawRect(track,302,34,3,this.listHeight,11190708,30);
         this.drawRect(track,302,thumbY,3,thumbHeight,16382711,100);
      }
   }
   function displayView()
   {
      this.displayed = true;
      this.renderSelection(this._index);
   }
   function addDisplayItemOnce(i, data)
   {
      this.renderSelection(this._index);
   }
   function jumpTo(nativeIndex)
   {
      this._index = nativeIndex;
      this.renderSelection(nativeIndex);
   }
   function scrollHighlightStyle(nativeIndex)
   {
      this.renderSelection(nativeIndex);
   }
   function moveSelection(direction)
   {
      this.rebuildOrder();
      if(this.order.length == 0)
      {
         return;
      }
      var position = this.positions[this._index];
      if(position == undefined)
      {
         position = 0;
      }
      position = (position + direction + this.order.length) % this.order.length;
      this.jumpTo(this.order[position].nativeIndex);
   }
   function storeDataChange(nativeIndex, paramIndex, value)
   {
      // Keep the game's original slot array; only the display order is sorted.
      this.dataList[nativeIndex][paramIndex] = value;
   }
   function destroy()
   {
      var i = 0;
      while(i < this.itemList.length)
      {
         this.itemList[i].removeMovieClip();
         this.headings[i].removeMovieClip();
         i++;
      }
      this.panelMC.removeMovieClip();
      this.panelMC = undefined;
      this.dataList = [];
      this.itemList = [];
      this.headings = [];
      this.order = [];
      this.positions = [];
      this.orderDirty = true;
      this.displayed = false;
      this._index = 0;
      this.topEdge = 0;
      this.highlightedItem = -1;
   }
}
