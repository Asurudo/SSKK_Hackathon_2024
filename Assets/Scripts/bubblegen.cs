using System.Collections.Generic;
using UnityEngine;

namespace Assets.Scripts
{
    public class NewMonoBehaviour : MonoBehaviour
    {
        public GameObject objectForSpawn;
        private List<SpawnObject> spawnObjectList;
        private int objectCount = 50;

        private void Start()
        {
            Debug.Log("?");
            CreateCollections();
            Generate(objectCount);
        }
        void CreateCollections()
        {
            spawnObjectList = new List<SpawnObject>();
        }
        void Generate(int objectCount)
        {
            CreateObjects();
            void CreateObjects()
            {
                for (int i = 0; i < objectCount; i++)
                {
                    Vector3 objectPosition = GetPosition();
                    SpawnObject sO = new SpawnObject(objectPosition);
                    spawnObjectList.Add(sO);
                }
            }
            SpawnGameObjects();
            void SpawnGameObjects()
            {
                List<SpawnObject> spawnedObjects = new List<SpawnObject>();
                List<SpawnObject> notSpawnedObjects = new List<SpawnObject>();

                foreach (SpawnObject item in spawnObjectList)
                {
                    Vector3 spawnPosition = GetPosition();
                    if (item.objectPosition != spawnPosition)
                    {
                        Instantiate(objectForSpawn, spawnPosition, transform.rotation);
                        spawnedObjects.Add(item);
                    }
                    else
                    {
                        notSpawnedObjects.Add(item);
                    }
                }
                Debug.Log("Object spawned :" + spawnedObjects.Count);
                Debug.Log("Object notSpawned :" + notSpawnedObjects.Count);
            }
        }
        Vector3 GetPosition()
        {
            Vector3 randmPosition;
            randmPosition.x = Random.Range(1, 100);
            randmPosition.y = Random.Range(1, 100);
            randmPosition.z = Random.Range(1, 100);
            return randmPosition;
        }
    }
    public class SpawnObject
    {
        public Vector3 objectPosition;
        public SpawnObject(Vector3 objectPosition)
        {
            this.objectPosition = objectPosition;
        }

    }
    //In case you want serialize this position for example for save you better use float[3] for position then vector.
}
