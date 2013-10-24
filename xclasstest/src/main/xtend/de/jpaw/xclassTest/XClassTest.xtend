package de.jpaw.xclassTest;

import de.jpaw.activeAnnotations.Implements

interface Hello {
    def Long getRef(int zz)
}


class HelloDispatcher implements Hello {
    override Long getRef(int zz) { return 7777L }
}

@Implements(typeof(Hello))
class HelloTest2 { 
    def public static void getRef(int uu) {
        
    }   
}
