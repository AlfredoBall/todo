using AutoMapper;

using Todo.Data.Access;
using E = Todo.Data.Entity;

namespace Todo.Data.Service.Mappings;

public class ItemMapper : Profile
{
    public ItemMapper()
    {
        CreateMap<E.Item, Item>();
    }
}
