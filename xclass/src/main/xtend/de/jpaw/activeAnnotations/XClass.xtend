package de.jpaw.activeAnnotations;

import java.util.concurrent.ConcurrentHashMap
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import java.util.Map
import java.util.List
import org.eclipse.xtend.lib.macro.declaration.Type
import java.lang.reflect.Method
import java.lang.reflect.InvocationTargetException

@Active(typeof(XClassProcessor))
annotation XClass {}

/** Annotation to specify the creation of an extended version of the Java "Class" object.
 * An XClass implements an Interface, which corresponds to a blueprint of static methods.
 * In other words, if a class has an XClass, you know it provides all the static methods listed in the interface.
 * In addition, those methods can be invoked through the XClass instance, without explicit reflection code to be implemented manually.
 * As a final option, the XClass can provide default implementations (for example if a default implementation in some common superclass can not be done,
 * because the source of that superclass is not available).
 *
 * Because there is exactly one instance per class, the annotated class must be final.
 *
 * As instance fields of the annotated class correspond to static fields per implementing class, this also allows a convenient way to ensure that uniform fields
 * are available.
 * A generics parameter of THIS is assumed to be the reference to the implementing class. It is not autogenerated in order to allow specification of a common
 * superclass.
 *
 * The companion annotation ISIClass will create a getter getXClass() which allows retrieval of this instance.
 */
 class XClassProcessor extends AbstractClassProcessor {


    override doTransform(MutableClassDeclaration cls, extension TransformationContext context) {
        val TypeParameterDeclaration myFirstTypeParameter = cls.typeParameters.head

        val meWildCardRef = if (myFirstTypeParameter == null) cls.newTypeReference else cls.newTypeReference(newWildcardTypeReference)
        val themWildCardRef = typeof(Class).newTypeReference(newWildcardTypeReference)
        val themTypeForInstanceRefs = if (myFirstTypeParameter == null) newWildcardTypeReference else myFirstTypeParameter.newTypeReference  // skip generics args!
        val themClassForInstanceRefs = typeof(Class).newTypeReference(themTypeForInstanceRefs)

        val hashMap = typeof(ConcurrentHashMap).newTypeReference(themWildCardRef, meWildCardRef)
        val map = typeof(Map).newTypeReference(themWildCardRef, meWildCardRef)
        val methodRef = typeof(Method).newTypeReference
        val exceptionRef = typeof(InvocationTargetException).newTypeReference


        cls.setFinal(true)
        cls.addField("implementingClass") [
            final = true
            visibility = Visibility::PRIVATE
            type = themClassForInstanceRefs
        ]
        cls.addMethod("getImplementingClass") [
            returnType = themClassForInstanceRefs
            visibility = Visibility::PUBLIC
            body = [ '''return implementingClass;''' ]
            docComment = '''Returns the Class pointed to by this instance'''
        ]
        cls.addField("allClasses") [
            final = true
            static = true
            visibility = Visibility::PRIVATE
            type = map
            initializer = [ '''new «toJavaCode(hashMap)»(20)''' ]
        ]
        cls.addMethod("registerClass") [
            synchronized = true
            static = true
            returnType = meWildCardRef
            docComment = '''Creates a new «cls.simpleName» instance pointing to subclass or returns the unique reference to an existing one for subclass'''
            addParameter("subclass", themWildCardRef)
            body = [ '''
                «toJavaCode(meWildCardRef)» newRef = allClasses.get(subclass);
                if (newRef == null) {
                    newRef = new «cls.simpleName»(subclass);
                    allClasses.put(subclass, newRef);
                }
                return newRef;
            ''']
        ]
        // add private fields for all methods, to cache references (avoiding reflection loookup later)
        cls.implementedInterfaces.forEach[
            recurseInterfaces[ m | cls.addField(m.privateFieldName) [
                visibility = Visibility::PRIVATE
                final = true
                type = methodRef
                docComment = '''access to method «m.simpleName»'''
            ]]
        ]
        val StringBuilder constructorCode = new StringBuilder('''
            this.implementingClass = implementingClass;
            try {''')
        cls.implementedInterfaces.forEach[
            recurseInterfaces[ m | constructorCode.append('''
                «m.privateFieldName» = implementingClass.getDeclaredMethod("«m.simpleName»");
            ''') ]]
        constructorCode.append('''
            } catch (Exception e) {
                throw new TypeNotPresentException(implementingClass.getName(), e);
            }
        ''')
        cls.addConstructor[
            visibility = Visibility::PRIVATE
            addParameter("implementingClass", themClassForInstanceRefs)
            body = [ constructorCode ]
        ]
        /*
        for (i: cls.implementedInterfaces) {
            recurseInterfaces(i, [
                cls.addMethod(it.simpleName) [
                    returnType = it.returnType
                    body = [ '''TODO;''' ]
                ] ])
        } */

        cls.implementedInterfaces.forEach[
            recurseInterfaces[ m |
                // workaround for Xtend 2.4 bug, assume generics parameter is the same as in this class! Does not work otherwise.
                val overrideReturnType = if (m.returnType.simpleName == myFirstTypeParameter?.simpleName) myFirstTypeParameter.newTypeReference
                cls.addMethod(m.simpleName) [
                    returnType = overrideReturnType ?: m.returnType
                    exceptions = m.exceptions
                    // docComment = '''Return type was «m.returnType»'''  // results in name exactly as used in interface
                    // parameters.forEach[addParameter(simpleName, it.type) ]
                    for (p : m.parameters)
                        addParameter(p.simpleName, p.type)
                    body = [ '''
                        try {
                            «IF m.returnType != primitiveVoid»
                                return («(overrideReturnType ?: m.returnType).simpleName»)
                            «ENDIF»
                            «m.privateFieldName».invoke(null«FOR p : m.parameters BEFORE ', ' SEPARATOR ', '»«p.simpleName»«ENDFOR»);
                        } catch (IllegalAccessException | IllegalArgumentException | «toJavaCode(exceptionRef)» _e) {
                            throw new TypeNotPresentException(implementingClass.getName(), _e);
                        }
                    ''' ]  // invoke the precalculated reflection address
                ]
            ]
        ]

    }
    def static privateFieldName(MethodDeclaration m) {
        "_m" + Integer::toHexString(m.hashCode)
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
