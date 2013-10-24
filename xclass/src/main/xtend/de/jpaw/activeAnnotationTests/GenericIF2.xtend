package de.jpaw.activeAnnotationTests;

import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration

@Active(typeof(GenericsInterface2Processor))
annotation GenericsInterface2 {
}

 class GenericsInterface2Processor extends AbstractClassProcessor {

    override doTransform(MutableClassDeclaration cls, extension TransformationContext context) {

        val if1 = cls.implementedInterfaces.head.type as InterfaceDeclaration
        for (m: if1.declaredMethods)
                if (m.returnType != primitiveVoid)
                    cls.addField(m.simpleName) [
                        type = m.returnType       // expectation: this should transfer the return type, with Generics parameters replaced
                    ]

    }

}
