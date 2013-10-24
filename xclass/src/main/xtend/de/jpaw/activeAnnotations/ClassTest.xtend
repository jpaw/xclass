package de.jpaw.activeAnnotations;

import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtend.core.macro.declaration.JvmClassDeclarationImpl

@Active(typeof(ClassTestProcessor))
annotation ClassTest {
    Class <?> value
}

 class ClassTestProcessor extends AbstractClassProcessor {


    override doTransform(MutableClassDeclaration cls, extension TransformationContext context) {
        val myAnnoRef = typeof(ClassTest).newTypeReference
        val xclassRef = cls.findAnnotation(myAnnoRef.type).getValue("value")
        val jvmType = xclassRef as org.eclipse.xtext.common.types.JvmGenericType
        val theType = findTypeGlobally(jvmType.qualifiedName) as JvmClassDeclarationImpl
        
        cls.docComment = '''
            Parameter is of type «xclassRef»
            Q is «jvmType.qualifiedName»
            I is «jvmType.identifier»
            T is «theType»
            '''

        cls.addField("xClassInstance") [
            static = true
            final = true
            type = String.newTypeReference
            visibility = Visibility::PUBLIC
            initializer = [ '''«jvmType.identifier».now().toString()''']
        ]
        
        val theClass = findClass(jvmType.qualifiedName)
        if (theClass != null)
        theClass.declaredMethods.forEach[ m |
            cls.addField('''xx«m.simpleName.toFirstUpper»''') [
                static = true
                type = m.returnType
            ]
        ]
        else
            cls.addField("notFound") [type = primitiveInt ]


        theType.declaredMethods.forEach[ m |
            cls.addField('''zz«m.simpleName.toFirstUpper»''') [
                static = true
                type = m.returnType
            ]
        ]

    }
}
