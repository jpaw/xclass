package de.jpaw.activeAnnotations

import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtend.core.macro.declaration.JvmClassDeclarationImpl
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration

@Active(typeof(ImplementsStaticProcessor))
annotation ImplementsStatic {
    Class <?> value
}

 class ImplementsStaticProcessor extends AbstractClassProcessor {

    override doTransform(MutableClassDeclaration cls, extension TransformationContext context) {
        val myAnnoRef = ImplementsStatic.newTypeReference
        val xclassRef = cls.findAnnotation(myAnnoRef.type).getValue("value")
        
        if (xclassRef == null || !JvmGenericType.isAssignableFrom(xclassRef.class)) {
            cls.addError('''invalid annotation parameter type''')
            return
        }
        val jvmType = xclassRef as JvmGenericType
        val xClassGeneric = findTypeGlobally(jvmType.qualifiedName)
        
        if (xClassGeneric == null || !JvmClassDeclarationImpl.isAssignableFrom(xClassGeneric.class)) {
            cls.addError('''invalid annotation parameter type: «jvmType.qualifiedName» is not available or not a class''')
            return
        }
        val xClassType = findTypeGlobally(jvmType.qualifiedName) as JvmClassDeclarationImpl

        cls.addField("xClassInstance") [
            static = true
            final = true
            type = xClassType.newTypeReference
            visibility = Visibility::PRIVATE
            initializer = [ '''«xClassType.newTypeReference».registerClass(«cls.simpleName».class)''']
            docComment = '''References the instance of «xClassType.simpleName» which represents this class'''
        ]
        cls.addMethod("getXClassInstance") [
            static = true
            visibility = Visibility::PUBLIC
            returnType = xClassType.newTypeReference
            body = [ '''return xClassInstance;''' ]
        ]
        
        //cls.docComment = '''xclass is of type «xClassType.class.name»'''
        // perform some checks: xclass must implement at least one interface, and this class must provide all methods of that interface as static methods
        // of public accessibility, with compatible return types
        /*
        if (xClassType.implementedInterfaces.size < 1) {
            cls.addError('''Referenced class must implement at least one interface''')
            return
        }
        val relevantInterface = xClassType.implementedInterfaces.head.type as InterfaceDeclaration
        cls.docComment = '''
            «FOR m:relevantInterface.declaredMethods»
                «m.returnType.simpleName» «m.simpleName»(«m.parameters.map['''«type» «simpleName»'''].join(', ')»);
            «ENDFOR»
        '''
        * 
        */
        // relevantInterface.declaredMethods.forEach []
    }
}
