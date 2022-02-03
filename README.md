# PRÉSENTATION

Ce projet est constitué de plusieurs scripts terraform, d'un script python, d'un dataset, et du nécessaire à la dockerisation de l'application (Dockerfile, requirements)

# TESTER L'APPLICATION EN LOCAL AVEC DOCKER

Lancer la commande
```
docker build -t iktos_test
```
Puis lancer 
```
docker run -it iktos_test
```
Vous pouvez maintenant accéder à l'application en local.


Vous pouvez tester les endpoints suivant : 

```
/getRow/<number>
#Retourne la ligne correspondant à l'index demandé
/getColumnMeanValue/<number>
#Retourne la valeur moyenne d'une colonne (si la colonne est constituée de nombre)
/getColumnMostFrequentValue/<number>
#Retourne la valeur la plus fréquente d'une colonne
/getColumnMedian/<number>
#Retourne la valeur médiane d'une colonne (si la colonne est consituée de nombre)
/getRandomRow
#Retourne une ligne aléatoire du dataset
```
# DÉPLOIEMENT DE L'APPLICATION

Vous devez tout d'abord remplir un fichier ~/.aws/credentials avec les credentials de votre compte AWS (utilisateur IAM)

Pour déployer l'application dans votre propre compte AWS, il vous suffit d'aller dans le dossier terraform et de jouer les commandes : 

```
terraform init 
terraform apply
```

### ATTENTION ###
Pour ne pas continuer de payer, j'ai mis le nombre de tâche à 0 pour mon ECS. Vous pouvez changer ce paramètre à la ligne 108 du fichier instance.tf.

Vous pouvez paramétrer la région dans laquelle vous sou
haitez déployer votre infrastructure dans le fichier variables.tfvars (ou en ligne de commande avec l'option --var=ma-region)

Une fois l'infrastructure déployée, allez dans la partie "Elastic Container Registry" de la console AWS, retrouvez votre repository, sélectionnez le et cliquez sur "View push commands". Suivez ensuite les instructions.

Si vous voulez pouvoir accéder à l'application depuis votre ordinateur, vous devez rajouter votre IP dans les autorisations du security group du load balancer (ligne 159 du fichier instance.tf). Je n'ai mis que mon IP à moi pour le moment.

Vous trouverez le lien de votre application ainsi déployée dans la partie EC2 de la console AWS, puis dans la partie "Load balancer" (DNS Name).

# TESTER DEPUIS MON ENVIRONNEMENT DE TEST

Si vous voulez tester depuis mon environnement de test à moi, vous pouvez me contacter, je redémarrerai mon service (vous devez également me fournir une IP depuis laquelle vous souhaiteriez accéder à mon application).


# CHOIX TECHNIQUES ET FONCTIONNALITÉ

Ma première idée a été de développé l'application dockerisée dans un AWS Lightsail : idéal pour notre cas (petite application web, peu coûteux), mais terraform ne prend pas encore en compte les containers Lightsail.
Je suis donc partie avec la solution plus classique d'un Elastic Container Registry et Elastic Container Service.
C'est un service qui est capable de se mettre facilement à l'échelle automatiquement. 

## Auto-Scaling
Pour cela, j'ai utilisé le composant AWS Auto Scaling, qui met automatiquement à l'échelle mon service quand l'utilisation de CPU dépasse 20% (c'est une valeur de test, on utilisera pas cette valeur en production). Par défaut nous n'avons qu'une seule tâche qui tourne sur le service, mais si l'utilisation CPU dépasse les 20%, on pourra avoir jusqu'à 4 tâches en simultané. Si l'utilisation de CPU redescend en dessous des 20%, le service se remet à l'échelle et n'utilisera qu'une seule tâche.

## Logs et métriques
Pour les logs et les métriques de mon application, j'ai décidé d'utiliser AWS Cloudwatch, parce que c'était le plus simple à mettre en place, et elle me semble suffisament complète. Ils sont accessibles depuis la partie "Cloudwatch" de la console AWS.

## Sécurité
Un pare-feu virtuel (un "security group") est mis en place afin de protéger mon application. Je n'ai autorisé pour le moment que mon IP à accéder à cette dernière. De plus, les logs sont chiffrés grâce à une clef créée avec le gestionnaire de clef AWS (depuis terraform). Une rotation des clefs est effectuée chaque année.
J'ai voulu mettre en place la certification SSL (pour avoir le protocle HTTPS) sur mon application mais cela nécessitait l'achat d'un nom de domaine (et faire un alias grâce à Route 53).

## Optimisation des coûts
J'ai choisi le plus petit nombre de tâche et la plus petite capacité Mémoire/CPU pour mon service, car il n'a pas besoin de plus. 