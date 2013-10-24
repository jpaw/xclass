package de.jpaw.activeAnnotationTests;

import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration

@Active(typeof(GenericsInterfaceProcessor))
annotation GenericsInterface {
}

 class GenericsInterfaceProcessor extends AbstractClassProcessor {

    override doTransform(MutableClassDeclaration cls, extension TransformationContext context) {

        cls.implementedInterfaces.forEach[
            recurseInterfaces[ m |
                (void)cls.addMethod(m.simpleName) [
                    returnType = m.returnType       // expectation: this should transfer the return type, with Generics parameters replaced
                    exceptions = m.exceptions
                    // parameters.forEach[addParameter(simpleName, it.type) ]
                    for (p : m.parameters)
                        addParameter(p.simpleName, p.type)
                    body = [ '''
                        «IF m.returnType != primitiveVoid»
                            return null;
                        «ENDIF»
                    ''' ]
                ]
            ]
        ]
    }

    // InterfaceDeclaration
    def void recurseInterfaces(TypeReference ii, (MethodDeclaration) => void g) {
        val InterfaceDeclaration i = ii.type as InterfaceDeclaration
        for (m : i.declaredMethods)
            g.apply(m)
        for (x : i.extendedInterfaces)
            recurseInterfaces(x, g)
    }

}
