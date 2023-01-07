/*
    Developer : zorm#0101

    Autosplitter for mario kart wii on dolphin, 32 tracks (no glitch & glitch)
    my comments are in my language (French), I'm not good enough to translate technical code correctly, use an automatic translator if necessary

*/

//cibler l'émulateur dolphin
state("Dolphin") {
}



startup{

    /*
        La wii utilise le big Endian, lors de la lecteur de valeur d'un pointeur il faut effectuer une conversion.
        Pour tout les pointeurs sur 1 byte il n'y a pas besoin de conversion (car le sens de lecteur n'a pas d'importance, il n'y a qu'une valeur)

        Pour ceux sur 2 ou 4 bytes il faut inverser la lecture, pour ça deux fonctions sont initialisé dans le startup

        remerciment à Jujstme#6860 (discord) de m'avoir donner la syntaxe et l'explication pour cette fonction
    */

    //fonction pour les int (4bytes)
    vars.ToLittleEndian = (Func<int, int>)(input => {
        byte[] temp = BitConverter.GetBytes(input);
        Array.Reverse(temp);
        return BitConverter.ToInt32(temp, 0);
    });

    //fonction pour les short (2bytes)
    vars.ToLittleEndianShort = (Func<short, short>)(input => {
        byte[] temp = BitConverter.GetBytes(input);
        Array.Reverse(temp);
        return BitConverter.ToInt16(temp, 0);
    });

    vars.GetNameMap = (Func<int, string>)(map => {
        switch (map){
            case 0x08:
                return "Luigi Circuit";
            case 0x01:
                return "Moo Moo Meadows	";
            case 0x02:
                return "Mushroom Gorge";
            case 0x04:
                return "Toad's Factory";
            case 0x00:
                return "Mario Circuit";
            case 0x05:
                return "Coconut Mall";
            case 0x06:
                return "DK Summit";
            case 0x07:
                return "Wario's Gold Mine";
            case 0x09:
                return "Daisy Circuit";
            case 0x0F:
                return "Koopa Cape";
            case 0x0B:
                return "Maple Treeway";
            case 0x03:
                return "Grumble Volcano";
            case 0x0E:
                return "Dry Dry Ruins";
            case 0x0A:
                return "Moonview Highway";
            case 0x0C:
                return "Bowser's Castle";
            case 0x0D:
                return "Rainbow Road";
            case 0x10:
                return "GCN Peach Beach";
            case 0x14:
                return "DS Yoshi Falls";
            case 0x19:
                return "SNES Ghost Valley 2";
            case 0x1A:
                return "N64 Mario Raceway";
            case 0x1B:
                return "N64 Sherbet Land";
            case 0x1F:
                return "GBA Shy Guy Beach";
            case 0x17:
                return "DS Delfino Square";
            case 0x12:
                return "GCN Waluigi Stadium";
            case 0x15:
                return "DS Desert Hills";
            case 0x1E:
                return "GBA Bowser Castle 3";
            case 0x1D:
                return "N64 DK's Jungle Parkway";
            case 0x11:
                return "GCN Mario Circuit";
            case 0x18:
                return "SNES Mario Circuit 3";
            case 0x16:
                return "DS Peach Gardens";
            case 0x13:
                return "GCN DK Mountain";
            case 0x1C:
                return "N64 Bowser's Castle";
            default:
                return "none";
        }
    });

}

init {
    //variable permettant de savoir quand la course est finalisé
    vars.ispass = false;
    //variable permettant de savoir si le run est lancé
    vars.isstart = false;
    //variable contenant l'id de la course actuel : https://wiki.tockdom.com/wiki/List_of_Identifiers#Courses
    vars.idcourse = 0x0;
    //variable permettant de savoir si la dernière course est finalisé
    vars.speedrundone = false;
    //dictionnaire contenant le temps pour chaque course
    vars.ITimerRecord = new Dictionary<int, TimeSpan>();
    //variable contenant les watchers des pointeurs créé
    vars.watchers = new MemoryWatcherList();
    //pointeur qui contiendra l'addresse de base de la mémoire MEM2
    IntPtr ptr = IntPtr.Zero;
    //détecte si le joueur est entré dans le menu solo
    vars.isinsolo = false;

    //function récupérer sur un code déjà existant pour retrouver la MEM2
    var scanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
    ptr = game.MemoryPages(true).FirstOrDefault(p => p.Type == MemPageType.MEM_MAPPED && p.State == MemPageState.MEM_COMMIT && (int)p.RegionSize == 0x2000000).BaseAddress;
                print("  => MEM2 address found at 0x" + ptr.ToString("X"));
    if (ptr == IntPtr.Zero) throw new Exception("Sigscan failed!");

    vars.ptr = ptr;

    /*
        Explication de la façon dont j'ai récupéré les pointeurs qui m'intéressais : https://github.com/aldelaro5/Dolphin-memory-engine

        Dolphin memory engine permet d'effectuer des recherches de valeur dans la mémoire de la même façon que cheat engine
        Une fois la valeur trouver il y a deux situations :

            1 - le pointeur est statique, c'est à dire que même après redémarrage de dolphin/pc l'addresse de la valeur sera toujours la même

            2 -l'addresse est dynamique, il faudra à partir d'un pointeur statique retrouver l'emplacement du pointeur dynamique (ça n'est pas toujours possible)
    */


    /*
        1) Pointeur statique, ici j'ai récupérer l'addresse des pointeurs qui contiennent un booléen,
        ici par exemple le "InGame" si le joueur est entrain de faire la course, si il met le jeu en pause par exemple, cette variable sera à 0

        Une fois que le pointeur est trouvé il suffit de l'ajouter au pointeur "ptr", qui est le début de MEM2, ce qui nous donnera par la suite le pointeur dans la mémoire "réel" du pointeur que l'on souhaite
    */
    vars.watchers.Add(new MemoryWatcher<byte> (ptr + 0x000002FA36E - 0x00000020000) { Name = "InGame"});
    vars.watchers.Add(new MemoryWatcher<byte> (ptr + 0x000009E1877 - 0x00000020000) { Name = "InPause"});
    vars.watchers.Add(new MemoryWatcher<byte> (ptr + 0x000009C26B3) { Name = "IdGame"});
                       
    // vars.pointinmenu = 0x313C823;
    // vars.ptrtest = ptr + vars.pointinmenu;
    // print(vars.ptrtest.ToString("X"));

    // vars.watchers.Add(new MemoryWatcher<byte> (ptr + vars.pointinmenu) { Name = "InMenu"});

    /*
        Fin des pointeurs statiques
        -----------------------------------
    */

}


update {

    //ici UpdateAll permet de récupérer en continue les valeurs contenu dans le "watchers"
    vars.watchers.UpdateAll(game);

    /*
        2) Pointeur dyamique, ici toute les pointeurs sont dynamique, pour retrouver les pointeurs il faut partir d'une structure restant statique, dans tout mes pointeurs je pars de la structure "raceinfo"
        
            Pour pouvoir trouver les pointeurs la ressource https://github.com/SeekyCt/mkw-structures/blob/bcc4f19aa04ac7bf45e6a4de72f43a779899fe6c/raceinfo.h est nécéssaire, je remercie grandement CLF78#1139 (discord) de m'avoir appris à lire le document
    */

    //création de l'objet memorywatcher, ici "update" recréera en continu cette objet, puisque les données sont dynamique les pointeurs deviennent obselète en plein jeu, il faut donc les recréé en continue
    vars.watchersmemory = new MemoryWatcherList();

    // print("id menu : 0x" + vars.watchers["InMenu"].Current.ToString("X"));
    // print("id game : 0x" + vars.watchers["IdGame"].Current.ToString("X"));


    //récupération du pointeur statique raceinfo : 809bd730 -> https://github.com/SeekyCt/mkw-structures/blob/bcc4f19aa04ac7bf45e6a4de72f43a779899fe6c/raceinfo.h#L109
    vars.watchersmemory.Add(new MemoryWatcher<int> (vars.ptr + 0x000009BD730) { Name = "Memory0"});
    vars.watchersmemory.UpdateAll(game);

    /*
        récupération du pointeur RaceinfoPlayer ** players -> https://github.com/SeekyCt/mkw-structures/blob/bcc4f19aa04ac7bf45e6a4de72f43a779899fe6c/raceinfo.h#L122
        Pour obtenir ce pointeur il faut effectuer un décalage de 0xC, utilisez dolphin memory engine pour comprendre comment la mémoire est stocké en partant du premier pointeur (raceinfo.h#L109)
    */
    vars.intvalue = (int)vars.ToLittleEndian(vars.watchersmemory["Memory0"].Current);
    vars.intvalue = unchecked((int)0x00080000000 + (int)vars.intvalue + 0xC);
    vars.watchersmemory.Add(new MemoryWatcher<int> (vars.ptr + vars.intvalue) { Name = "Memory1"});
    vars.watchersmemory.UpdateAll(game);

    /*
        RaceinfoPlayer ** players est un pointeur de plusieurs autre pointeur, tout ces pointeurs indique les informations de chaque joueur en course, le premier joueur de la liste sera celui de votre joueur à vous
    */
    vars.intvalue1 = (int)vars.ToLittleEndian(vars.watchersmemory["Memory1"].Current);
    vars.intvalue1 = unchecked((int)0x00080000000 + (int)vars.intvalue1);
    IntPtr ptrtest = vars.ptr + vars.intvalue1;
    vars.watchersmemory.Add(new MemoryWatcher<int> (ptrtest) { Name = "Memory2"});
    vars.watchersmemory.UpdateAll(game);

    /*
        Une fois notre joueur sélectionner nous nous retrouvons ici dans la structure : https://github.com/SeekyCt/mkw-structures/blob/bcc4f19aa04ac7bf45e6a4de72f43a779899fe6c/raceinfo.h#L71
        Dans cette exemple que je n'utilise plus maintenant, vous pouvez par exemple récupérer avec un décalage de 0x2C le frameCounter, le nombre de frame écouler depuis le début de la map en cours : https://github.com/SeekyCt/mkw-structures/blob/bcc4f19aa04ac7bf45e6a4de72f43a779899fe6c/raceinfo.h#L89
    */
    vars.intvalue2  = (int)vars.ToLittleEndian(vars.watchersmemory["Memory2"].Current);
    vars.intvalue2  = unchecked((int)0x00080000000 + (int)vars.intvalue2 + 0x2C);
    IntPtr ptrtest2 = vars.ptr + vars.intvalue2;
    vars.watchersmemory.Add(new MemoryWatcher<int> (ptrtest2) { Name = "Memory3"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalue3  = (int)vars.ToLittleEndian(vars.watchersmemory["Memory3"].Current);
    vars.realtime = vars.intvalue3;
    vars.starttimer = vars.intvalue3-404.8; //environ la frame du 0 lors du décompte 3,2,1
    vars.calctime = (vars.starttimer/60); //division de la frame par 60 pour récupérer les secondes écoulé (peu précis)
    // Fin de l'exemple
    //-----------------------------


    /*
        De la même façon que le code ci-dessus, je récupére le timer du timer manager : https://github.com/SeekyCt/mkw-structures/blob/bcc4f19aa04ac7bf45e6a4de72f43a779899fe6c/raceinfo.h#L57
        Il correspond au réel chrono de la course en cours, il est constitué de cette façon : https://github.com/SeekyCt/mkw-structures/blob/bcc4f19aa04ac7bf45e6a4de72f43a779899fe6c/raceinfo.h#L38
        MAIS : il ne s'arrête pas quand le joueur principal finit la course, il continue de tourner, donc je n'ai pas pu l'utiliser pour récupérer le temps final
    */
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
    // print("time : " + vars.timerv2.ToString());

    //---- FINISH TIMER
    /*
        Pour récupérer le timer de fin du joueur je dois retrouver ceci : https://github.com/SeekyCt/mkw-structures/blob/bcc4f19aa04ac7bf45e6a4de72f43a779899fe6c/raceinfo.h#L102
        J'aimerais aimer n'utiliser que ce timer mais malheureusement le pointeur ne se crée que à la FIN de la course du joueur

        EXPLICATION :   pour avoir l'ingame time qui tourne je me base d'abord sur le vars.timerv2, et dès que le joueur à finit sa course, donc dès que le vars.timerfinish est rempli, je
                        change l'ingame time avec le vars.timerfinish, comme ça le temps est parfaitement entrée tout en ayant en continue le timer qui tourne !
    */
    vars.intvalf = (int)vars.ToLittleEndian(vars.watchersmemory["Memory2"].Current);
    vars.intvalf = unchecked((int)0x00080000000 + (int)vars.intvalf + 0x00000040);
    vars.watchersmemory.Add(new MemoryWatcher<int> (vars.ptr + vars.intvalf) { Name = "MemoryF1"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalf1 = (int)vars.ToLittleEndian(vars.watchersmemory["MemoryF1"].Current);

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

    //milli
    vars.intvalf6 = unchecked((int)0x00080000000 + (int)vars.intvalf1 + 0x8);
    vars.watchersmemory.Add(new MemoryWatcher<short> (vars.ptr + vars.intvalf6) { Name = "MemoryF4"});
    vars.watchersmemory.UpdateAll(game);

    vars.intvalf7 = (short)vars.ToLittleEndianShort((short)vars.watchersmemory["MemoryF4"].Current);
    // print("milli : "+ vars.intvalf7.ToString());


    vars.timerfinish = TimeSpan.FromMinutes(vars.intvalf3);
    vars.timerfinish += TimeSpan.FromSeconds(vars.intvalf5);
    vars.timerfinish += TimeSpan.FromMilliseconds(vars.intvalf7);
    // print("time : " + vars.timerfinish.ToString());


    
    /*
        récupération de la scène encore pour pouvoir gérer par la suite les start et reset
    */
    vars.watchersmemory.Add(new MemoryWatcher<int> (vars.ptr + 0x000009C1E38) { Name = "MemorySceneId1"});
    vars.watchersmemory.UpdateAll(game);

    vars.intmenu = (int)vars.ToLittleEndian(vars.watchersmemory["MemorySceneId1"].Current);
    // print("pointeur : " + vars.intmenu.ToString("X"));
    
    vars.intmenu = unchecked((int)vars.intmenu - (int)0x8E000000);
    //216B328
    // print("pointeur after : " + vars.intmenu.ToString("X"));
    
    vars.watchersmemory.Add(new MemoryWatcher<int> (vars.ptr + vars.intmenu) { Name = "MemorySceneId2"});
    vars.watchersmemory.UpdateAll(game);

    vars.intmenu1 = (int)vars.ToLittleEndian(vars.watchersmemory["MemorySceneId2"].Current);
    // print("pointeur2 : " + vars.intmenu1.ToString("X"));
    
    vars.intmenu1 = unchecked((int)0x00080000000 + (int)vars.intmenu1);

    vars.watchersmemory.Add(new MemoryWatcher<int> (vars.ptr + vars.intmenu1) { Name = "MemorySceneId3"});
    vars.watchersmemory.UpdateAll(game);

    vars.scene = (int)vars.ToLittleEndian(vars.watchersmemory["MemorySceneId3"].Current);

    /*
        Fin de la gestion des pointeurs pour le menu
        -------------------------
    */

} 

split {



    //j'effectue le dernier split "manuellement", car sinon le timer s'arrêterais après avoir cliquer sur "suivant" à la dernière map, alors que le mieux est lorsque le dernier chrono ingame time est fini
    if(vars.speedrundone == true){

        /*
            Affichage d'une popup avec le détail des temps de chaque course
            Livesplit ne peut pas afficher les millièmes de seconde, je me sers donc d'une popup externe pour afficher l'ingame time à l'exactitude
        */
        int keyWidth = 25;
        int valueWidth = 10;
        string message = "";
        TimeSpan totalTimer = TimeSpan.FromSeconds(0);
        foreach(var item in vars.ITimerRecord){
            string racename = vars.GetNameMap(item.Key);
            string key = racename.PadRight(keyWidth);
            string value = item.Value.ToString().PadRight(valueWidth);
            message += "| " + key + " | " + value + " |\n";
            totalTimer += item.Value;
        }

        string titleall = "All";
        titleall = titleall.PadRight(keyWidth);
        message += "| " + titleall + " | " + totalTimer.ToString().PadRight(valueWidth) + " |\n";

        Thread t = new Thread(() => MessageBox.Show(message, "Result time", MessageBoxButtons.OK, MessageBoxIcon.Information));
        t.Start();

        vars.speedrundone = false;
        return true;
    }

    /*
        ce code permet de savoir si nous avons changé de map, si nous changeons de map alors on split, ceci ce fait donc dans le chargement de la prochaine map, l'endroit a peu d'importance car l'ingame time
        ne bougera pas durant les temps de chargement ni durant les temps de "fin de course (caméra de fin, bouton suivant/quitter)" 
    */
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
    //détecte si nous sommes encore dans le menu du jeu, si nous passons hors menu, le timer se lance, ça n'est pas exactement au "OK" mais à une seconde prêt, de toute façon le real time a maintenant peu d'importance
    if (vars.scene == 0x0 && vars.isinsolo == true && vars.isstart == false) {
        timer.IsGameTimePaused = true;
        vars.isstart = true;
		return true;
	}else if(vars.scene == 0x48){
        vars.isinsolo = true;
    }else{
        vars.isinsolo = false;
    }
}

//anien sytème de chargement, je n'en n'ai pas besoin car mon ingame time est correctement lié au jeu
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
    //je check si le timerfinish existe
    if(vars.timerfinish > TimeSpan.FromSeconds(1)){
        //j'enregistre dans un dictionnaire l'id de la map et la valeur du timer
        vars.ITimerRecord[vars.watchers["IdGame"].Current] = vars.timerfinish;
        if(vars.watchers["IdGame"].Current == 0x1C){
            //si c'est la dernière map alors le speedrun est fini maintenant!
            vars.speedrundone= true;
        }
    }else{
        //si le joueur est en course alors le timer s'enregistrera avec le timer global de la map en attendant ( et non le vrai timer du joueur)
        if(vars.timerv2 != TimeSpan.FromSeconds(0) && vars.watchers["InGame"].Current == 1){
            vars.ITimerRecord[vars.watchers["IdGame"].Current] = vars.timerv2;
        }
    }
    
    //initialisation du timer poure retourner la valeur à livesplit
    TimeSpan allTimer = TimeSpan.FromSeconds(0);
    
    //ajout de l'ensemble des timers de toute les courses dans la variable
    foreach(var item in vars.ITimerRecord){
        // print("key : " + item.Key);
        // print("value : " + item.Value);
        allTimer += item.Value;
    }
    
    // print("temps : " + allTimer);
    //on retourne le timer
    return allTimer;
}

reset {
    //si on détecte que le joueur est retourné au menu on reset
    if(vars.scene == 0x41 || vars.scene == 0x54 || vars.scene == 0x55 || vars.scene == 0x7A){
        return true;
    }else{
        return false;
    }
}

onReset {
    //lors du reset on clean quelque variable
    vars.ispass = false;
    vars.isstart = false;
    vars.idcourse = 0x0;
    vars.speedrundone = false;
    vars.ITimerRecord = new Dictionary<int, TimeSpan>();
}
