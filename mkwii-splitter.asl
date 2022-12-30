state("Dolphin") {
}

startup{
    vars.ToLittleEndian = (Func<int, int>)(input => {
        byte[] temp = BitConverter.GetBytes(input);
        Array.Reverse(temp);
        return BitConverter.ToInt32(temp, 0);
    });

    vars.ToLittleEndianShort = (Func<short, short>)(input => {
        byte[] temp = BitConverter.GetBytes(input);
        Array.Reverse(temp);
        return BitConverter.ToInt16(temp, 0);
    });
}

init {
    vars.doneMaps = new List<byte>(); 
    vars.ispass = false;
    vars.isstart = false;
    vars.nbpass = 0;
    vars.idcourse = 0x0;
    vars.actualmap = 0;
    vars.speedrundone = false;

    vars.ITimerRecord = new Dictionary<int, TimeSpan>();

    vars.watchers = new MemoryWatcherList();
    IntPtr ptr = IntPtr.Zero;

    var scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
    ptr = game.MemoryPages(true).FirstOrDefault(p => p.Type == MemPageType.MEM_MAPPED && p.State == MemPageState.MEM_COMMIT && (int)p.RegionSize == 0x2000000).BaseAddress;
                print("  => MEM2 address found at 0x" + ptr.ToString("X"));
    if (ptr == IntPtr.Zero) throw new Exception("Sigscan failed!");

    vars.ptr = ptr;

    //910AE2C8
    vars.watchers.Add(new MemoryWatcher<byte> (ptr + 0x000002FA36E - 0x00000020000) { Name = "InGame"});
    vars.watchers.Add(new MemoryWatcher<byte> (ptr + 0x000009E1877 - 0x00000020000) { Name = "InPause"});
    vars.watchers.Add(new MemoryWatcher<byte> (ptr + 0x000009C26B3) { Name = "IdGame"});

    vars.pointinmenu = 0x000002C2D14 + 0x2DEB5B4;
    vars.ptrtest = ptr + vars.pointinmenu;
    // print("ptrtest : 0x"+vars.ptrtest.ToString("X"));
    vars.watchers.Add(new MemoryWatcher<byte> (ptr + vars.pointinmenu) { Name = "InMenu"});



    // vars.watchers.Add(new MemoryWatcher<byte> (ptr + 0x000009BD731) { Name = "Memory1"});
    // vars.watchers.Add(new MemoryWatcher<byte> (ptr + 0x000009BD732) { Name = "Memory2"});
    // vars.watchers.Add(new MemoryWatcher<byte> (ptr + 0x000009BD733) { Name = "Memory3"});

    // Type t = timer.StartTime.GetType(); // Where obj is object whose properties you need.
    // PropertyInfo [] pi = t.GetProperties();
    // foreach (PropertyInfo p in pi)
    // {
    //     print(p.Name + " : " + p.GetValue(timer.StartTime));
    // }
}

update {

    vars.watchers.UpdateAll(game);

    // print("autosplitter ok");
    vars.watchersmemory = new MemoryWatcherList();
    // print("id menu : 0x" + vars.watchers["InMenu"].Current.ToString("X"));
    // print("id game : 0x" + vars.watchers["IdGame"].Current.ToString("X"));

    //récupération du pointeur statique raceinfo : 809bd730
    vars.watchersmemory.Add(new MemoryWatcher<int> (vars.ptr + 0x000009BD730) { Name = "Memory0"});
    vars.watchersmemory.UpdateAll(game);

    //récupération du pointeur statique playerinfo
    vars.intvalue = (int)vars.ToLittleEndian(vars.watchersmemory["Memory0"].Current);
    vars.intvalue = unchecked((int)0x00080000000 + (int)vars.intvalue + 0xC);
    vars.watchersmemory.Add(new MemoryWatcher<int> (vars.ptr + vars.intvalue) { Name = "Memory1"});
    vars.watchersmemory.UpdateAll(game);

    //récupération du pointeur statique playerinfo
    vars.intvalue1 = (int)vars.ToLittleEndian(vars.watchersmemory["Memory1"].Current);
    vars.intvalue1 = unchecked((int)0x00080000000 + (int)vars.intvalue1);
    IntPtr ptrtest = vars.ptr + vars.intvalue1;
    vars.watchersmemory.Add(new MemoryWatcher<int> (ptrtest) { Name = "Memory2"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalue2  = (int)vars.ToLittleEndian(vars.watchersmemory["Memory2"].Current);
    vars.intvalue2  = unchecked((int)0x00080000000 + (int)vars.intvalue2 + 0x2C);
    IntPtr ptrtest2 = vars.ptr + vars.intvalue2;
    vars.watchersmemory.Add(new MemoryWatcher<int> (ptrtest2) { Name = "Memory3"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalue3  = (int)vars.ToLittleEndian(vars.watchersmemory["Memory3"].Current);
    vars.realtime = vars.intvalue3;
    vars.starttimer = vars.intvalue3-404.8;
    vars.calctime = (vars.starttimer/60);


    //dev
    vars.intvalue4 = (int)vars.ToLittleEndian(vars.watchersmemory["Memory0"].Current);
    vars.intvalue4 = unchecked((int)0x00080000000 + (int)vars.intvalue4 + 0x14);
    vars.watchersmemory.Add(new MemoryWatcher<int> (vars.ptr + vars.intvalue4) { Name = "MemoryA1"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalue5 = (int)vars.ToLittleEndian(vars.watchersmemory["MemoryA1"].Current);
    // print("addr : 0x"+ vars.intvalue5.ToString("X"));

    vars.intvalue6 = unchecked((int)0x00080000000 + (int)vars.intvalue5 + 0x8);
    vars.watchersmemory.Add(new MemoryWatcher<short> (vars.ptr + vars.intvalue6) { Name = "MemoryA2"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalue7 = (short)vars.ToLittleEndianShort((short)vars.watchersmemory["MemoryA2"].Current);
    // print("minute : "+ vars.intvalue7.ToString());


    vars.intvalueA6 = unchecked((int)0x00080000000 + (int)vars.intvalue5 + 0xA);
    vars.watchersmemory.Add(new MemoryWatcher<byte> (vars.ptr + vars.intvalueA6) { Name = "MemoryA3"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalue8 = vars.watchersmemory["MemoryA3"].Current;
    // print("second : "+ vars.intvalue8.ToString());


    vars.intvalueB6 = unchecked((int)0x00080000000 + (int)vars.intvalue5 + 0xC);
    vars.watchersmemory.Add(new MemoryWatcher<short> (vars.ptr + vars.intvalueB6) { Name = "MemoryA4"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalue9 = (short)vars.ToLittleEndianShort((short)vars.watchersmemory["MemoryA4"].Current);
    // print("milli : "+ vars.intvalue9.ToString());

    vars.timerv2 = TimeSpan.FromMinutes(vars.intvalue7);
    vars.timerv2 += TimeSpan.FromSeconds(vars.intvalue8);
    vars.timerv2 += TimeSpan.FromMilliseconds(vars.intvalue9);

    //---- FINISH TIMER

    //récupération du pointeur du timer de fin
    vars.intvalf = (int)vars.ToLittleEndian(vars.watchersmemory["Memory2"].Current);
    vars.intvalf = unchecked((int)0x00080000000 + (int)vars.intvalf + 0x00000040);
    vars.watchersmemory.Add(new MemoryWatcher<int> (vars.ptr + vars.intvalf) { Name = "MemoryF1"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalf1 = (int)vars.ToLittleEndian(vars.watchersmemory["MemoryF1"].Current);

    // print("pointeur timer de fin : " + vars.intvalf1.ToString("X"));

    //min
    vars.intvalf2 = unchecked((int)0x00080000000 + (int)vars.intvalf1 + 0x4);
    vars.watchersmemory.Add(new MemoryWatcher<short> (vars.ptr + vars.intvalf2) { Name = "MemoryF2"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalf3 = (short)vars.ToLittleEndianShort((short)vars.watchersmemory["MemoryF2"].Current);
    // print("min : "+ vars.intvalf3.ToString());
   
   //sec
    vars.intvalf4 = unchecked((int)0x00080000000 + (int)vars.intvalf1 + 0x6);
    vars.watchersmemory.Add(new MemoryWatcher<byte> (vars.ptr + vars.intvalf4) { Name = "MemoryF3"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalf5 = vars.watchersmemory["MemoryF3"].Current;
    // print("second : "+ vars.intvalf5.ToString());

    //sec
    vars.intvalf6 = unchecked((int)0x00080000000 + (int)vars.intvalf1 + 0x8);
    vars.watchersmemory.Add(new MemoryWatcher<short> (vars.ptr + vars.intvalf6) { Name = "MemoryF4"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalf7 = (short)vars.ToLittleEndianShort((short)vars.watchersmemory["MemoryF4"].Current);
    // print("milli : "+ vars.intvalf7.ToString());


    vars.timerfinish = TimeSpan.FromMinutes(vars.intvalf3);
    vars.timerfinish += TimeSpan.FromSeconds(vars.intvalf5);
    vars.timerfinish += TimeSpan.FromMilliseconds(vars.intvalf7);
    // print("time : " + vars.timerv2.ToString());

} 

split {

    if(vars.speedrundone == true){
        vars.speedrundone = false;
        return true;
    }

    if(vars.ispass == false){
        if(vars.watchers["InGame"].Current > 0){
            vars.idcourse = vars.watchers["IdGame"].Current;
            vars.ispass = true; 
        }
    }else{
        if(vars.watchers["InGame"].Current == 0 && vars.idcourse != vars.watchers["IdGame"].Current){
            vars.ispass = false;
            return true;
        }
    }
}

start
{
	if (vars.watchers["InMenu"].Current == 0 && vars.isstart == false) {
        timer.IsGameTimePaused = true;
        vars.isstart = true;
		return true;
	}
}

isLoading { // Returning True pauses the timer for that tick.
    // print("ingame : " + vars.watchers["InGame"].Current);
    // if (vars.watchers["InGame"].Current == 0) {
    //     timer.IsGameTimePaused = true;
    //     return true;
    // }else if(vars.realtime >= 412) {
    //     timer.IsGameTimePaused = false;
    //     return false;
    // }
}

gameTime
{
    if(vars.timerfinish > TimeSpan.FromSeconds(1)){
        // print("test : " + vars.timerfinish);
        vars.ITimerRecord[vars.watchers["IdGame"].Current] = vars.timerfinish;
        if(vars.watchers["IdGame"].Current == 0x1C){
            vars.speedrundone= true;
        }
    }else{
        if(vars.timerv2 != TimeSpan.FromSeconds(0) && vars.watchers["InGame"].Current == 1){
            vars.ITimerRecord[vars.watchers["IdGame"].Current] = vars.timerv2;
        }
    }
    
    TimeSpan allTimer = TimeSpan.FromSeconds(0);
    
    foreach(var item in vars.ITimerRecord){
        // print("key : " + item.Key);
        // print("value : " + item.Value);
        allTimer += item.Value;
    }
    
    // print("temps : " + allTimer);

    return allTimer;
}

reset {
    if(vars.watchers["InMenu"].Current == 1){
        return true;
    }else{
        return false;
    }
}

onReset {
    vars.doneMaps = new List<byte>(); 
    vars.ispass = false;
    vars.isstart = false;
    vars.nbpass = 0;
    vars.idcourse = 0x0;
    vars.actualmap = 0;
    vars.speedrundone = false;
    vars.ITimerRecord = new Dictionary<int, TimeSpan>();
}
