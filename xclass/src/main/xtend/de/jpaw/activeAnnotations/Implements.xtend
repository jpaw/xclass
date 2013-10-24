package de.jpaw.activeAnnotations

import org.eclipse.xtend.core.macro.declaration.JvmInterfaceDeclarationImpl
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtend.core.macro.declaration.JvmClassDeclarationImpl
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration

@Active(typeof(ImplementsProcessor))
annotation Implements {
    Class <?> value
}

 class ImplementsProcessor extends AbstractClassProcessor {

    override doTransform(MutableClassDeclaration cls, extension TransformationContext context) {
        val myAnnoRef = Implements.newTypeReference
        val xclassRef = cls.findAnnotation(myAnnoRef.type).getValue("value")
        
        if (xclassRef == null || !JvmGenericType.isAssignableFrom(xclassRef.class)) {
            cls.addError('''invalid annotation parameter type''')
            return
        }
        val jvmType = xclassRef as JvmGenericType
        val xClassGeneric = findTypeGlobally(jvmType.qualifiedName)
        
        if (xClassGeneric == null || !JvmInterfaceDeclarationImpl.isAssignableFrom(xClassGeneric.class)) {
            cls.addError('''invalid annotation parameter type: «jvmType.qualifiedName» is not available or not an interface''')
            return
        }
        val xClassType = findTypeGlobally(jvmType.qualifiedName + "Dispatcher") as JvmClassDeclarationImpl
        val xInterfaceType = findTypeGlobally(jvmType.qualifiedName) as JvmInterfaceDeclarationImpl

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
        
        cls.docComment = '''
            «FOR m:xInterfaceType.declaredMethods»
                «m.returnType.simpleName» «m.signature»;
            «ENDFOR»
        '''
        for (m: xInterfaceType.declaredMethods) {
            val myImplementation = cls.findDeclaredMethod(m.simpleName, m.parameters.map[type])
            if (myImplementation == null) {
                cls.addError('''An implementation of «m.signature» is missing''')
                return
            }
            if (!myImplementation.static || myImplementation.visibility != Visibility.PUBLIC) {
                myImplementation.addError('''The implementation of «m.signature» must be public and static''')
                return
            }
        }
    }
    
    def getSignature(MutableMethodDeclaration m) {
        '''«m.simpleName»(«m.parameters.map['''«type» «simpleName»'''].join(', ')»)'''
    }
}
